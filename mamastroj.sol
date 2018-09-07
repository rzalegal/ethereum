pragma solidity ^0.4.24;

/* This is v0.2 MamaStroj smart contract with logging in system implemented.
   ### Major changes:
   Client struct (+ bool logged);
   Deal struct refers to client now (+ address cli);
   Deals can be privitized (+ Deal hidden);
   New mapping from addresses to pass hashes (+ mapping passes);
   */

contract MamaStroj
{
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
        checkPass(_pass);
        clients[msg.sender].logged = true;
        emit Authorized(clients[msg.sender].name, msg.sender);
    }
    
    function createDeal(address _cli, string _desc)
    public
    {
        bytes32 _id = keccak256(now);
        Deal memory _newDeal = Deal(_cli, _desc, _id, false, false, false);
        deals[_cli].push(_newDeal);
        deal_id[_id] = _newDeal;
    }
    
    function dealInfo(bytes32 _id, string pass)
    public
    returns(address client, string description)
    {
        Deal memory info = deal_id[_id];
        return(info.cli, info.desc);
    }
    
    function approveDeal(bytes32 _id)
    public
    returns(bool success)
    {
        deal_id[_id].approved = true;
    }
    
    function confirmDeal(bytes32 _id)
    public
    returns(bool success)
    {
        deal_id[_id].confirmed = true;
    }

    function setPrivate(bytes32 _id)
    public
    roots(_id)
    auth(_id)
    returns(bool success)
    {
    	Deal storage p = deal_id[_id];
    	assert(!p.hidden);
    	p.hidden = true;
    }

    
    event Authorized(string, address);
    event Signed_In(string, address);
    event Password_Match();
    
}