pragma solidity 0.4.24;

contract Ballot {
    
    uint256 votingDuration;
    uint256 endTime;
    
    struct Voter {
        uint256 weight;
        bool already;
        uint256 votedFor;
        address delegate;
    }
    
    struct Proposal {
        bytes32 name;
        uint256 total;
    }
    
    uint256 beginTime;
    
    address owner;
    
    mapping (address => Voter) voters;
    
    Proposal[] proposals;
    
    modifier isOwner() {
        require(owner == msg.sender);
        _;
    }
    
    modifier notCheater() {
        Voter storage sender = voters[msg.sender];
        if(sender.already) {
            emit CheaterCaught("Address:", msg.sender, "Timestamp:", now);
            require(1==0, "Cheter Caught! See `Events` section");
        }
        _;
    }
    
    modifier notOver() {
        uint256 nowtime = now;
        if (endTime < nowtime) {
            emit VotingIsOver(nowtime - endTime, "seconds ago");
            require(1==0, "Voting is Over! See `Events` section");
        }
        _;
    }
    
    constructor(bytes32[] memory names, uint256 duration) 
    public
    {
        
        owner = msg.sender;
        votingDuration = duration * 1 minutes; 
        endTime = now + votingDuration;
        
        for (uint256 i = 0; i < names.length; i++) {
            proposals.push(Proposal({
                name: names[i],
                total: 0
            }));
        }
        
        voters[msg.sender].weight = 1;
    }
    
    function delegateTo(address _to)
    public
    notCheater
    {
        Voter storage sender = voters[msg.sender];
        
        while (sender.delegate != msg.sender && sender.delegate != address(0)) {
            sender.delegate = _to;
            _to = voters[_to].delegate;
        }
        
        sender.delegate = _to;
        sender.already = true;
        
        if (voters[_to].already) {
            proposals[voters[_to].votedFor].total += sender.weight;
        } else {
            voters[_to].weight += sender.weight;
        }
    }
    
    function throwBallot(uint256 _no)
    public
    notCheater
    returns(bool success)
    {
        Voter storage sender = voters[msg.sender];
        sender.already = true;
        sender.votedFor = _no;
        proposals[_no].total += 1;
        return true;
    }
    
    function windex()
    internal
    view
    isOwner
    returns(uint256 index)
    {
        for (uint256 i = 0; i < proposals.length; i++) {
            uint256 max;
            if (proposals[i].total > max) {
                max = proposals[i].total;
                index = i;
            }
        }
        return index;
    }
    
    function overallWinner()
    public
    view
    isOwner
    returns(bytes32 _name)
    {
        return proposals[windex()].name;
    }
    
    event VotingIsOver(uint256, string);
    event CheaterCaught(string, address, string, uint256);
}
