// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserContract {

    struct UserDetails{
        string name;    
        string gender;    
        uint32 age;
        uint32 candidateVotedFor;   
        address userAddress;    
    }  
    
    UserDetails private userData; 
    uint accessId;
    address private owner;

    struct AccessControl{
        address givenTo;
        uint exipry;
    }

    //AccessControl[] private _accessControl;
    mapping(address=> bool ) private _accessCheck;
    mapping(address=> mapping(bool=>uint)) private _accessExpiration;

    constructor(string memory _name, string memory _gender, uint32 _age) {
        userData = UserDetails(_name, _gender, _age, 0, msg.sender);
        owner = msg.sender;
    }

    function giveAccess(address _add, uint _expiry) external returns(bool){
        require(msg.sender == owner, "only the owner can give access");
        require(_add != address(0),"can not give zero address");
        if(_accessCheck[_add]==true){
            return false; //access already given, 
        }else{            
            uint expiry = (_expiry>0)? block.timestamp+_expiry : block.timestamp+864000; //default 10 days
            _accessCheck[_add] = true;
            _accessExpiration[_add][true] = expiry;            
            return true; //permission set correctly
        }
    }

    function getDetails() external view returns(UserDetails memory){
        address caller = tx.origin;
        require(msg.sender == owner || _accessCheck[caller]==true && 
                block.timestamp < _accessExpiration[caller][true],
                "no access to get details");
        
        return userData;
    }

    function updateVotedCandidate(uint32 _candidateId) external {
        userData.candidateVotedFor = _candidateId;
    }


}