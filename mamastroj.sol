pragma solidity ^0.4.24;
import "./security.sol";

contract MamaStroj is Security
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

    modifier roots(bytes32 _id)
    {
    	require(deal_id[_id].cli == msg.sender);
    	_;
    }
    
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

    Security sc;

    constructor(uint8 _secureLevel)
    public
    {
    	sc = Security(_secureLevel);
    	owner = msg.sender;
    }
    
    function checkPass(string memory pass)
    internal
    {
        assert(keccak256(pass) == passes[msg.sender]);
        emit Password_Match();
    }
    
    function SignIn(string name, string _pass)
    public
    {
        Base.push(Client(name, msg.sender, false));
        passes[msg.sender] = keccak256(_pass);
        clients[msg.sender].name = name;
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
    
    function createDeal(address _cli, string _desc)
    public
    {
        bytes32 _id = keccak256(now);
        Deal memory _newDeal = Deal(_cli, _desc, _id, false, false, false);
        deals[_cli].push(_newDeal);
        deal_id[_id] = _newDeal;
        emit deal_Created(now, _cli);
    }
    
    function dealInfo(bytes32 _id)
    public
    view
    auth(_id)
    returns(address client, string description)
    {
        Deal storage info = deal_id[_id];
        return(info.cli, info.desc);
    }
    
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

    event Authorized(string passhash, address user);
    event Signed_In(string passhash, address user);
   	event Password_Match();
    event set_Private(bytes32 _id);
    event set_Public(bytes32 _id);
    event deal_Approved(uint256 time, bytes32 _id);
    event deal_Confirmed(uint256 time, bytes32 _id);
    event deal_Created(uint256 time, address _for);
}