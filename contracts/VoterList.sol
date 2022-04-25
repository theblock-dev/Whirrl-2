// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./UserContract.sol";

contract VoterList {


  address[] private votersList;
  mapping(address => address) userContractList; //user address to user contract address mapping
  mapping(address=>bool) private registeredVoter;
  address private admin;

  constructor() {
    admin = msg.sender;
  }

  function addVoter(address _address) external onlyAdmin() {    
    votersList.push(_address);
    registeredVoter[_address] = true;  
  }

  function getVoters() external view returns(address[] memory){
    return votersList;
  }

  function initUserContract(address _userAdd, address _smartAdd) external 
    nonZeroAddress(_userAdd)
    nonZeroAddress(_smartAdd)
    onlyAdmin(){    
    userContractList[_userAdd] = _smartAdd;
  }

  function getUserContractAddress(address _userAddress) external view 
  nonZeroAddress(_userAddress) 
  returns(address){
    return userContractList[_userAddress];
  }

  function getUserDetails(address _contractAddress) external view nonZeroAddress(_contractAddress)
    returns(UserContract.UserDetails memory){
    return UserContract(_contractAddress).getDetails();
  }

  function isRegistered() external view returns(bool){
    return registeredVoter[msg.sender];    
  }

  modifier onlyAdmin(){
    require(msg.sender == admin,'only owner can call');
    _;
  }

  modifier nonZeroAddress(address _add){
    require(_add != address(0),"zero address not allowed");
    _;
  }

}
