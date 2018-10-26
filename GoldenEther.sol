pragma solidity ^0.4.24;

contract ethMMM {

    struct Investor
    {
        uint id;
        uint deposit;
        uint deposits;
        uint date;
        uint avaliable;    //Добавлено для реализации модификатора ограничения частоты "ручных" выплат;
        address referrer;
    }

    address public owner;
    address public admin;
    uint constant public TX_LIMIT = 150;
    uint constant public MINIMUM_INVEST = 0.01 ether;
    uint constant public INTEREST = 3; // СТАВКА ДЛЯ ВЫПЛАТ ПО ДЕПОЗИТАМ (+ ЕДИНОВРЕМЕННЫЙ КЭШБЭК)
    uint constant public REFRATE = 7; //СТАВКА ДЛЯ ВЫПЛАТ РЕФЕРУ
    uint public depositAmount;
    uint public round;
    uint public lastPaymentDate;
    address[] public addresses;
    mapping(address => Investor) public investors;
    bool public pause;

    address[3] best;


    event Invest(address addr, uint amount, address referrer);
    event Payout(address addr, uint amount, string eventType, address from);
    event NewRoundStarted(uint round, uint date, uint deposit);
    event BestInvestorChanged(address addr, uint deposit);

//"require" вместо условной конструкции
    modifier onlyOwner
    {
        require(owner == msg.sender);
        _;
    }
// Добавлен модификатор функции ручного запроса части выплаты с временным ограничением
    modifier oncePer(uint timeslice)
    {
        Investor storage user = investors[msg.sender];
        if (user.avaliable < now)
        {
            _;
            user.avaliable = now + timeslice;
        }
    }

    constructor()
    public
    {
        owner = msg.sender;
        admin = msg.sender;
        addresses.length = 1;
        round = 1;
    }


    function transferOwnership(address addr)
    onlyOwner
    public
    {
        owner = addr;
    }

    function() payable public {

        require(owner != msg.sender);

        if (0 == msg.value) {
            payoutSelf();
            return;
        }

        require(false == pause, "Name is restarting. Please wait.");
        require(msg.value >= MINIMUM_INVEST, "Too small amount, min. amount is 0.01 ether");
        Investor storage user = investors[msg.sender];

        if (user.id == 0) {
            msg.sender.transfer(0 wei);
            addresses.push(msg.sender);
            user.id = addresses.length;
            user.date = now;

            address referrer = toAddress(msg.data);
            if (investors[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        } else {
            payoutSelf();
        }

        user.deposit += msg.value;
        user.deposits += 1;

        emit Invest(msg.sender, msg.value, user.referrer);

        depositAmount += msg.value;
        lastPaymentDate = now;

        admin.transfer(msg.value / 100 * 19);
        address(this).transfer(msg.value / 100 * 81);
        uint bonusAmount = (msg.value / 100) * REFRATE;
        uint cashback = (msg.value / 100) * INTEREST;

        if (user.referrer != 0x0) {
            if (user.referrer.send(bonusAmount)) {
                emit Payout(user.referrer, bonusAmount, "referral", msg.sender);
            }

            if (user.deposits == 1) { // cashback only for the first deposit
                if (msg.sender.send(cashback)) {
                    emit Payout(msg.sender, bonusAmount, "cash-back", 0);
                }
            }
        }



        if (user.deposit > investors[best[0]].deposit) {
            best[2] = best[1];
            best[1] = best[0];
            best[0] = msg.sender;
            emit BestInvestorChanged(msg.sender, user.deposit);
        }
    }

    function payout(uint offset)
    public
    {
        if (pause == true) {
            Restart();
            return;
        }

        uint txs;
        uint amount;

        for (uint idx = addresses.length - offset - 1; idx >= 1 && txs < TX_LIMIT; idx--) {
            address addr = addresses[idx];
            if (investors[addr].date + 24 hours > now) {  //Если инвестор запрашивал выплату менее суток назад, ждет следующей
                continue;
            }

            amount = getInvestorUnpaidAmount(addr);
            investors[addr].date = now;

            if (address(this).balance < amount) { //Остановка выплат в случае недостатка средств на счёте контракта
                pause = true;
                return;
            }

            if (addr.send(amount)) {
                emit Payout(addr, amount, "daily payout", 0);
            }

            txs++;
        }
    }
//Пользовательский запрос на преждевременное получение частичной выплаты
    function payoutSelf()
    private
    oncePer(10 minutes) //Модификатор, ограничивающий частоту запросов
    {
        require(investors[msg.sender].id != 0, "Investor not found.");
        uint amount = getInvestorUnpaidAmount(msg.sender);

        if (address(this).balance < amount) {
            pause = true;
            return;
        }

        msg.sender.transfer(amount);
        emit Payout(msg.sender, amount, "self-payout", 0);
    }
//Перезапуск и начало нового инвест-раунда
    function Restart()
    private
    {
        uint txs;
        address addr;
        //Проход по списку адресов и удаление записей об инвесторах
        for (uint i = addresses.length - 1; i > 0; i--)
        {
            addr = addresses[i];
            addresses.length -= 1;
            delete investors[addr];
            assert(txs++ < TX_LIMIT);
        }

        emit NewRoundStarted(round, now, depositAmount);
        pause = false;
        round += 1;
        depositAmount = 0;
        lastPaymentDate = now;

        delete best;
    }

    function getInvestorCount()
    public
    view
    returns(uint)
    {
        return addresses.length - 1;
    }

//Расчет невыплаченной прибыли
    function getInvestorUnpaidAmount(address addr)
    public
    view
    returns(uint)
    {
        uint multiplier = (now - investors[addr].date) / 1 days; //Временной множитель;
        uint percent = investors[addr].deposit / 100 * INTEREST; //Процент на депозит;
        return percent * multiplier;
    }

    function WeeklyBest()
    public
    {
        if(best[0].send(2 ether)) {emit Payout(best[0], 2000, "1st weekly best payout", 0);}
        if(best[0].send(1 ether)) {emit Payout(best[1], 1000, "2nd weekly best payout", 0);}
        if(best[0].send(0.5 ether)) {emit Payout(best[2], 500, "3rd weekly best payout", 0);}
    }

//Конверсия из bytes в address посредством ассемблера
    function toAddress(bytes bys)
    private
    pure
    returns(address addr)
    {
        assembly
        {
            addr := mload(add(bys, 20))
        }
    }
}
