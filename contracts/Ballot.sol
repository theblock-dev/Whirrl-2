// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./UserContract.sol";
import "./VoterList.sol";

contract Ballot {

    uint public votingEndTime;
    uint private candidateCount;
    uint private votersCount;
    address private _admin;
    address private voterListContract;
    address[] private _voterList;


    struct Candidate {
        uint id;
        string name;
        uint voteCount;        
    }
    
    struct VoteMap{
        address voter;
        uint votedFor;
    }
        
    mapping(uint => Candidate) private _candidates;
    mapping (address => uint) private _votedFor;  //user address to candidate id
    mapping(address=>bool) private _alreadyVoted;
    mapping(address => bool) private _voters;
    VoteMap[] private _voteMap;
    

    constructor(uint _votingPeriod, address _voterListContract) {
        _admin = msg.sender;
        votingEndTime = block.timestamp + _votingPeriod;
        voterListContract = _voterListContract;
    }

    function addCandidates(string[] memory candidateNames) external onlyAdmin(){
        candidateCount = candidateNames.length;
        for(uint i=0;i<candidateNames.length;i++){
            _candidates[i] = Candidate(i,candidateNames[i],0);
        }
    }
    function addVoters(address[] memory voterList) external onlyAdmin(){
        for(uint i=0;i<voterList.length;i++){
            _voters[voterList[i]]= true;
        }
        votersCount = voterList.length;
        _voterList = voterList;
    }

    function castVote(uint32 _candidateId) external onlyVoter(msg.sender){
        require(_alreadyVoted[msg.sender]== false,"you can vote only once");
        require(block.timestamp < votingEndTime, "voting period over, can not vote anymore");
        _alreadyVoted[msg.sender]= true;
        _votedFor[msg.sender]=_candidateId;
        _candidates[_candidateId].voteCount++ ;
        _voteMap.push(VoteMap(msg.sender,_candidateId));
        //update user contract
        address _smartContract = VoterList(voterListContract).getUserContractAddress(msg.sender);
        UserContract(_smartContract).updateVotedCandidate(_candidateId);

    }

    function getMyVote() external view returns(uint){
        require(_alreadyVoted[msg.sender]== true,"you have not voted yet");
        return _votedFor[msg.sender];
    }

    function getUserVote(address _userAddress) external view onlyVoter(_userAddress) returns(uint){
        require(_alreadyVoted[_userAddress]== true,"this address has not voted yet");
        return _votedFor[_userAddress];
    }

    function getResults() public view onlyAdmin() returns(uint[] memory){
        require(block.timestamp > votingEndTime, "voting period not over yet");
        uint[] memory voteCount = new uint[](candidateCount);
        for(uint i=0;i<candidateCount;i++){
            voteCount[i]=_candidates[i].voteCount;
        }
        return voteCount;
    }

    function getVoteMap() external view onlyAdmin() returns(VoteMap[] memory){
       return _voteMap;
    }

    function consolidateVotes() external view onlyAdmin() returns(uint,uint){
        uint sumOfVotes;
        uint usersVoted;
        for(uint i=0;i<candidateCount;i++){
            sumOfVotes += _candidates[i].voteCount;
        }

        for(uint i=0;i<_voterList.length;i++){
            if(_alreadyVoted[_voterList[i]]==true){
                usersVoted++;
            }
        }

        return(sumOfVotes,usersVoted);
    }

    function getCandidate(uint id) external view returns(Candidate memory){
        return _candidates[id];
    }
    
    modifier onlyAdmin(){
        require(msg.sender == _admin,'only admin can call');
        _;
    }

    modifier onlyVoter(address _address){
        require(_voters[_address]==true,"The address is not a voter");
        _;
    }
  

}
