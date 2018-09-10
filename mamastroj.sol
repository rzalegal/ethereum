pragma solidity ^0.4.24;
//Any libraries/contracts were unattached for this version
contract MamaStroj
{
	address owner;
//Addr and Logged parameters removed
    struct Client
    {
        string name;
    }
//Shortened "id"    
    struct Deal
    {
        address cli;
        string desc;
        bytes32 id;
        bool approved;
        bool confirmed;
        bool hidden;
    }
//Base comes public    
    Client[] public Base;
    
    mapping (address => Client) clients;
    mapping (address => Deal[]) deals;
    mapping (bytes32 => Deal) ids;
    mapping (address => bytes32) passes;
//Admin modifier uses new Revertion() function
    modifier admin()
    {
    	Revertion(owner == msg.sender, "Authorized personnel only");
    	_;
    }
//So do roots()
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
//Revertion() is to revert transaction with comment
  	function Revertion(bool _cond, string _msg)
  	internal
  	pure
  	{
  		if (_cond)
  		{
  			revert(_msg);
  		}
  	}
//Updates Ids <=> Deals[]
  	function Update(uint256 num)
  	internal
  	view
  	{
  	    Deal storage _old = deals[msg.sender][num];
  	    Deal storage _new = ids[_old.id];
  	    _old = _new;
  	}
  	
//Reverting the deal by admin
  	function DEAL_REVERT(bytes32 _id)
  	public
  	admin
  	{
  		Deal storage rev = ids[_id];
  		Revertion(rev.approved || rev.confirmed, 
  		"Deal must be confirmed or approved at first");
  		rev.approved = false;
  		rev.confirmed = false;
  	}
//No passes - just for the name and for the base
    function SignIn(string name)
    public
    {
        clients[msg.sender] = Client(name);
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
//Full Deal info is given
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
//Using Revertion() in approve/confirm section not to waste gas 
//while duplicating transactions 
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
//To decide: whether it's allowed for admin or client only 
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
//Simple getter for deal ID
    function getID(uint8 deal_number)
    public
    view
    returns(bytes32 ID)
    {
        ID = deals[msg.sender][deal_number].id;
    }
//indexed events
    event Signed_In(string indexed name, address indexed user);
   	event Password_Match();
    event set_Private(bytes32 _id);
    event set_Public(bytes32 _id);
    event deal_Approved(uint256 indexed time, bytes32 indexed _id);
    event deal_Confirmed(uint256 indexed time, bytes32 indexed _id);
    event deal_Created(uint256 indexed time, address indexed _for);
}