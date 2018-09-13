pragma solidity ^0.4.24;
import "./security.sol";
import"./Errors.sol";

contract MamaStroj is Security(3), Errors
{
	address owner;

    struct Client
    {
        string name;
        address addr;
    }
    
    struct Deal
    {
        address cli;
        string desc;
        bytes32 id;
        bool approved;
        bool confirmed;
        bool hidden;
    }
    
    Client[] public Base;
    
    mapping (address => Client) clients;
    mapping (address => Deal[]) deals;
    mapping (bytes32 => Deal) ids;
    mapping (address => bytes32) passes;

    modifier admin()
    {
    	Revertion(owner != msg.sender, "Authorized personnel only");
    	_;
    }

    modifier roots(bytes32 _id)
    {
    	Revertion(ids[_id].hidden && ids[_id].cli != msg.sender,
    	"This deal has a private state.");
    	_;
    }
    
    constructor()
    public
    {
    	owner = msg.sender;
    }
  
  	function Update(uint256 num)
  	internal
  	view
  	{
  	    Deal storage _old = deals[msg.sender][num];
  	    Deal storage _new = ids[_old.id];
  	    _old = _new;
  	}
  	

  	function DEAL_REVERT(bytes32 _id)
  	public
  	admin
  	{
  		Deal storage rev = ids[_id];
  		Revertion(!(rev.approved || rev.confirmed), 
  		"Deal must be confirmed or approved at first");
  		rev.approved = false;
  		rev.confirmed = false;
  	}

    function SignIn(string name)
    public
    {
        clients[msg.sender] = Client(name, msg.sender);
        Base.push(clients[msg.sender]);
        emit Signed_In(name, msg.sender);
    }

    function newDeal(address _cli, string _desc)
    admin
    public
    {
        bytes32 _id = keccak256(now);
        Deal memory _newDeal = Deal(_cli, _desc, _id, false, false, false);
        deals[_cli].push(_newDeal);
        ids[_id] = _newDeal;
        emit deal_Created(now, _cli);
    }

    function dealInfo(bytes32 _id)
    public
    view
    roots(_id)
    returns(address client, string name, string Description, bool Approved,
    bool Confirmed, bool Private)
    {
        Deal storage info = ids[_id];
        return(info.cli, clients[info.cli].name, info.desc, info.approved, 
        info.confirmed, info.hidden);
    }

    function approveDealByID(bytes32 _id)
    public
    roots(_id)
    {
    	Deal storage _deal = ids[_id];
        Revertion(_deal.approved, "Deal is approved already!");
        _deal.approved = true;
        emit deal_Approved(now, _id);
    }

    function approveDealByNumber(uint256 num)
    public
    {
    	Deal storage _deal = ids[deals[msg.sender][num].id];
    	Revertion(_deal.approved, "Deal is approved already!");
    	_deal.approved = true;
    	Update(num);
    	emit deal_Confirmed(now, _deal.id);
    }

    function confirmDealByID(bytes32 _id)
    public
    admin
    {
        Deal storage _deal = ids[_id];
    	Revertion(_deal.confirmed, "Deal is confirmed already!");
    	_deal.confirmed = true;
        emit deal_Confirmed(now, _id);
    }

    function confirmDealByNumber(address _cli, uint256 num)
    public
    admin
    {
    	Deal storage _deal = ids[deals[_cli][num].id];
    	Revertion(_deal.confirmed, "Deal is confirmed already!");
    	_deal.confirmed = true;
    	Update(num);
    	emit deal_Confirmed(now, _deal.id);
    }

    function setPrivate(bytes32 _id)
    public
    {
    	Deal storage p = ids[_id];
    	Revertion(p.hidden, "This deal is private by default");
    	p.hidden = true;
    	emit set_Private(_id);
    }

    function setPublic(bytes32 _id)
    public
    roots(_id)
    {
    	Deal storage p = ids[_id];
    	Revertion(!p.hidden, "This deal is public by default");
    	p.hidden = false;
    	emit set_Public(_id);
    }

    function getID(uint8 deal_number)
    public
    view
    returns(bytes32 ID)
    {
        ID = deals[msg.sender][deal_number].id;
    }

    event Signed_In(string indexed name, address indexed user);
   	event Password_Match();
    event set_Private(bytes32 _id);
    event set_Public(bytes32 _id);
    event deal_Approved(uint256 indexed time, bytes32 indexed _id);
    event deal_Confirmed(uint256 indexed time, bytes32 indexed _id);
    event deal_Created(uint256 indexed time, address indexed _for);
}