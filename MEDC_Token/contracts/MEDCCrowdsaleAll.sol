pragma solidity ^0.4.20;

//standart library for uint
library SafeMath { 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}
//standart contract to identify owner
contract Ownable {

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

//Abstract Token contract
contract MEDCToken{
  function setCrowdsaleContract (address) public;
  function sendCrowdsaleTokens(address, uint256)  public;
  function endICO () public;
}

//Crowdsale contract
contract MEDCCrowdsale is Ownable{

  using SafeMath for uint;

  uint decimals = 18;

  // Token contract address
  MEDCToken public token;

  uint public tokenPrice = 7000; //7000 tokens for 1 ether;

  address public distributionAddress = 0x925EcbBAd1dc1b46e9dA57827BD3BD2Aa20937e8;

  // Constructor
  function MEDCCrowdsale(address _tokenAddress) public payable{    
    token = MEDCToken(_tokenAddress);
    owner = msg.sender;

    token.setCrowdsaleContract(this);
  }

  uint public constant MIN_DEPOSIT = 0.1 ether;

  //ICO CONSTANTS
  uint public constant PRE_ICO_MAX_CAP = 5000000000 ether;//5000000000*(uint(10).pow(decimals)); 
  uint public preIcoTokensSold;


  uint public ICO_START = 1522922400; // 5th April 2018 12:00 UTC+2
  uint public ICO_FINISH = ICO_START + 6 weeks;

  uint public ICO_MIN_CAP = 300 ether; // ether
  // uint public ICO_MAX_CAP = //all tokens;

  //END ICO CONSTANTS
  uint public tokensSold;
  uint public ethCollected;
  
  function getCurrentBonus (uint _time) public view returns(uint){
    if(_time == 0){
      _time = now;
    }

    if(_time + 7 days > now){
      return 30;
    }
    if(_time + 21 days > now){
      return 15;
    }
    return 10;
  }
  
  mapping (address => uint) public contributorEthCollected;
  
  function () public payable {
    require (ICO_START <= now && now <= ICO_FINISH);
    require (msg.value >= MIN_DEPOSIT);
    
    require (buy(msg.sender, msg.value, now));
  }

  function buy (address _address, uint _value, uint _time) internal returns(bool) {
    uint tokensToSend = _value.mul(tokenPrice);
    tokensToSend = tokensToSend.add(tokensToSend.mul(getCurrentBonus(_time))/100);

    ethCollected = ethCollected.add(_value);

    if (ICO_START + 3 weeks >= _time){
      if (preIcoTokensSold.add(tokensToSend) <= PRE_ICO_MAX_CAP){
        preIcoTokensSold = preIcoTokensSold.add(tokensToSend);
        distributionAddress.transfer(address(this).balance);
      }else{
        return false;
      }
    }

    if (ICO_START + 6 weeks >= _time){
      contributorEthCollected[_address] = contributorEthCollected[_address].add(_value);
      if (ethCollected >= ICO_MIN_CAP){
        distributionAddress.transfer(address(this).balance);
      }  
    }

    tokensSold = tokensSold.add(tokensToSend);
    token.sendCrowdsaleTokens(_address, tokensToSend);
    return true;    

  }

  function sendEtherManually (address _address, uint _value) public onlyOwner {
    require (buy(_address, _value, now));
  }

  function sendTokensManually (address _address, uint _value) public onlyOwner {
    tokensSold = tokensSold.add(_value);
    token.sendCrowdsaleTokens(_address,_value);
  }
  

  bool public isIcoFinished = false;

  function endICO () public onlyOwner {
    require (now > ICO_FINISH + 5 days && !isIcoFinished);
    isIcoFinished = true;
    token.endICO();
  }

  function refund () public {
    require (now > ICO_FINISH);
    require (contributorEthCollected[msg.sender] > 0);

    msg.sender.transfer(contributorEthCollected[msg.sender]);
    contributorEthCollected[msg.sender] = 0;
  }
}