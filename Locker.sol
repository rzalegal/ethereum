pragma solidity ^0.4.24;

contract Locker
{
    mapping (address => bool) locks;
    
    uint256 enabledAt = now;
    
    modifier every(uint256 t)
    {
        if (now >= enabledAt || owner == msg.sender 
        || locks[msg.sender] == false)
        {
            enabledAt = now + t;
            _;
        }
    }
    
    modifier admin()
    {
        require(owner == msg.sender);
        _;
    }
    
    modifier lock_After()
    {
        require(locks[msg.sender] == false 
        || owner == msg.sender);
        _;
        locks[msg.sender] = true;
    }
    
    address owner;
    
    constructor()
    public
    {
        owner = msg.sender;
    }
    
    function unclock(address _sub)
    public
    admin
    {
        locks[_sub] = false;
    }

    function lock(address _sub)
    public
    admin
    {
        locks[_sub] = true;
    }
}