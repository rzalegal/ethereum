pragma solidity ^0.4.24;

contract MamaStroj
{
	address owner;

    struct Client
    {
        string name;
        address addr;
        bool logged;
    }
    
    struct Deal
    {
        address cli;
        string desc;
        bytes32 identifier;
        bool approved;
        bool confirmed;
        bool hidden;
    }
    
    Client[] Base;
    
    mapping (address => Client) clients;
    mapping (address => Deal[]) deals;
    mapping (bytes32 => Deal) deal_id;
    mapping (address => bytes32) passes;
    
    modifier admin()
    {
    	require(owner == msg.sender);
    	_;
    }
//Root modifier (to be deprecated)
    modifier roots(bytes32 _id)
    {
    	require(deal_id[_id].cli == msg.sender);
    	_;
    }
//Authorization modifier
    modifier auth(bytes32 _id)
    {
        Deal storage p = deal_id[_id];
        if (p.hidden) 
            {
                if(!clients[msg.sender].logged)
                {
                    revert("You must be Authorized. Please, Log In.");
                }
            }
        _;
    }

    constructor()
    public
    {
    	owner = msg.sender;
    }
//Pass checking func
    function checkPass(string memory pass)
    internal
    {
        assert(keccak256(pass) == passes[msg.sender]);
        emit Password_Match();
    }
// SignIN/LogIN Module begin   
    function SignIn(string name, string _pass)
    public
    {
        clients[msg.sender] = Client(name, msg.sender, false);
        Base.push(clients[msg.sender]);
        passes[msg.sender] = keccak256(_pass);
        emit Signed_In(name, msg.sender);
    }
    
    function LogIn(string _pass)
    public
    {
        Client storage user = clients[msg.sender];
        checkPass(_pass);
        user.logged = true;
        emit Authorized(user.name, msg.sender);
    }
//Module end
//Admin function: create deal
    function newDeal(address _cli, string _desc)
    public
    {
        bytes32 _id = keccak256(now);
        Deal memory _newDeal = Deal(_cli, _desc, _id, false, false, false);
        deals[_cli].push(_newDeal);
        deal_id[_id] = _newDeal;
        emit deal_Created(now, _cli);
    }
//Get deal information (auth required)
    function dealInfo(bytes32 _id)
    public
    view
    auth(_id)
    returns(address client, string description)
    {
        Deal storage info = deal_id[_id];
        return(info.cli, info.desc);
    }
//Client approves deal before it's been confirmed
    function approveDeal(bytes32 _id)
    public
    roots(_id)
    returns(bool success)
    {
    	Deal storage _deal = deal_id[_id];
        if (_deal.approved)
        {
        	revert("Deal is approved already");
        }
        emit deal_Approved(now, _id);
    }
//Admin function (confirm deal by ID)
    function confirmDealByID(bytes32 _id)
    public
    admin
    returns(bool success)
    {
    	Deal storage _deal = deal_id[_id];
    	if (_deal.confirmed)
        {
        	revert("Deal is confirmed already");
        }
        emit deal_Confirmed(now, _id);
    }
//Swt deal state to private 
    function setPrivate(bytes32 _id)
    public
    roots(_id)
    returns(bool success)
    {
    	Deal storage p = deal_id[_id];
    	assert(!p.hidden);
    	p.hidden = true;
    	emit set_Private(_id);
    }
//Set deal state to public (auth required)
    function setPublic(bytes32 _id)
    public
    roots(_id)
    auth(_id)
    returns(bool success)
    {
    	Deal storage p = deal_id[_id];
    	assert(p.hidden);
    	p.hidden = false;
    	emit set_Public(_id);
    }
// Get deal ID by entering number in the list
    function getDealID(uint8 deal_number)
    public
    returns(bytes32 r)
    {
        r = deals[msg.sender][deal_number].identifier;
    }

    event Authorized(string name, address user);
    event Signed_In(string name, address user);
   	event Password_Match();
    event set_Private(bytes32 _id);
    event set_Public(bytes32 _id);
    event deal_Approved(uint256 time, bytes32 _id);
    event deal_Confirmed(uint256 time, bytes32 _id);
    event deal_Created(uint256 time, address _for);
}