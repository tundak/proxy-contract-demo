pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Referral is OwnableUpgradeable {
  using MathUpgradeable for uint;

  /**
   * @dev Max referral level depth
   */
  uint8 constant MAX_REFER_DEPTH = 3;

  /**
   * @dev Max referee amount to bonus rate depth
   */
  uint8 constant MAX_REFEREE_BONUS_LEVEL = 3;

  uint _decimals;
  uint _referralBonus;
  uint _secondsUntilInactive;
  bool _onlyRewardActiveReferrers;
  uint256[] _levelRate;
  uint256[] _refereeBonusRateMap;

  /**
   * @dev The struct of account information
   * @param referrer The referrer addresss
   * @param reward The total referral reward of an address
   * @param referredCount The total referral amount of an address
   * @param lastActiveTimestamp The last active timestamp of an address
   */
  struct Account {
    address payable referrer;
    uint reward;
    uint referredCount;
    uint lastActiveTimestamp;
  }

  /**
   * @dev The struct of referee amount to bonus rate
   * @param lowerBound The minial referee amount
   * @param rate The bonus rate for each referee amount
   */
  struct RefereeBonusRate {
    uint lowerBound;
    uint rate;
  }

  event RegisteredReferer(address referee, address referrer);
  event RegisteredRefererFailed(address referee, address referrer, string reason);
  event PaidReferral(address from, address to, uint amount, uint level);
  event UpdatedUserLastActiveTime(address user, uint timestamp);

  mapping(address => Account) public accounts;

  uint256[] levelRate;
  uint256 referralBonus;
  uint256 decimals;
  uint256 secondsUntilInactive;
  bool onlyRewardActiveReferrers;
  RefereeBonusRate[] refereeBonusRateMap;

   function initialize() public initializer {
      _levelRate=[600, 300, 100];
      _referralBonus=30;
      _decimals=1000;
      _secondsUntilInactive=8400;
      _onlyRewardActiveReferrers=true;
      _refereeBonusRateMap=[1, 500, 5, 750, 25, 1000];
      
        require(_levelRate.length > 0, "Referral level should be at least one");
        require(_levelRate.length <= MAX_REFER_DEPTH, "Exceeded max referral level depth");
        require(_refereeBonusRateMap.length % 2 == 0, "Referee Bonus Rate Map should be pass as [<lower amount>, <rate>, ....]");
        require(_refereeBonusRateMap.length / 2 <= MAX_REFEREE_BONUS_LEVEL, "Exceeded max referree bonus level depth");
        require(_referralBonus <= _decimals, "Referral bonus exceeds 100%");
        require(sum(_levelRate) <= _decimals, "Total level rate exceeds 100%");

        decimals = _decimals;
        referralBonus = _referralBonus;
        secondsUntilInactive = _secondsUntilInactive;
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
        levelRate = _levelRate;

        // Set default referee amount rate as 1ppl -> 100% if rate map is empty.
        if (_refereeBonusRateMap.length == 0) {
          refereeBonusRateMap.push(RefereeBonusRate(1, decimals));
          return;
        }

        for (uint i; i < _refereeBonusRateMap.length; i += 2) {
          if (_refereeBonusRateMap[i+1] > decimals) {
            revert("One of referee bonus rate exceeds 100%");
          }
          // Cause we can't pass struct or nested array without enabling experimental ABIEncoderV2, use array to simulate it
          refereeBonusRateMap.push(RefereeBonusRate(_refereeBonusRateMap[i], _refereeBonusRateMap[i+1]));
        }
    }

  // constructor(
  //   uint _decimals,
  //   uint _referralBonus,
  //   uint _secondsUntilInactive,
  //   bool _onlyRewardActiveReferrers,
  //   uint256[] memory _levelRate,
  //   uint256[] memory _refereeBonusRateMap
  // )
  //   public
  // {
  //   require(_levelRate.length > 0, "Referral level should be at least one");
  //   require(_levelRate.length <= MAX_REFER_DEPTH, "Exceeded max referral level depth");
  //   require(_refereeBonusRateMap.length % 2 == 0, "Referee Bonus Rate Map should be pass as [<lower amount>, <rate>, ....]");
  //   require(_refereeBonusRateMap.length / 2 <= MAX_REFEREE_BONUS_LEVEL, "Exceeded max referree bonus level depth");
  //   require(_referralBonus <= _decimals, "Referral bonus exceeds 100%");
  //   require(sum(_levelRate) <= _decimals, "Total level rate exceeds 100%");

  //   decimals = _decimals;
  //   referralBonus = _referralBonus;
  //   secondsUntilInactive = _secondsUntilInactive;
  //   onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
  //   levelRate = _levelRate;

  //   // Set default referee amount rate as 1ppl -> 100% if rate map is empty.
  //   if (_refereeBonusRateMap.length == 0) {
  //     refereeBonusRateMap.push(RefereeBonusRate(1, decimals));
  //     return;
  //   }

  //   for (uint i; i < _refereeBonusRateMap.length; i += 2) {
  //     if (_refereeBonusRateMap[i+1] > decimals) {
  //       revert("One of referee bonus rate exceeds 100%");
  //     }
  //     // Cause we can't pass struct or nested array without enabling experimental ABIEncoderV2, use array to simulate it
  //     refereeBonusRateMap.push(RefereeBonusRate(_refereeBonusRateMap[i], _refereeBonusRateMap[i+1]));
  //   }
  // }

  function sum(uint[] memory data) public pure returns (uint) {
    uint S;
    for(uint i;i < data.length;i++) {
      S += data[i];
    }
    return S;
  }


  /**
   * @dev Utils function for check whether an address has the referrer
   */
  function hasReferrer(address addr) public view returns(bool){
    return accounts[addr].referrer != address(0);
  }

  /**
   * @dev Get block timestamp with function for testing mock
   */
  function getTime() public view returns(uint256) {
    return block.timestamp; // solium-disable-line security/no-block-members
  }

  /**
   * @dev Given a user amount to calc in which rate period
   * @param amount The number of referrees
   */
  function getRefereeBonusRate(uint256 amount) public view returns(uint256) {
    uint rate = refereeBonusRateMap[0].rate;
    for(uint i = 1; i < refereeBonusRateMap.length; i++) {
      if (amount < refereeBonusRateMap[i].lowerBound) {
        break;
      }
      rate = refereeBonusRateMap[i].rate;
    }
    return rate;
  }

  function isCircularReference(address referrer, address referee) internal view returns(bool){
    address parent = referrer;

    for (uint i; i < levelRate.length; i++) {
      if (parent == address(0)) {
        break;
      }

      if (parent == referee) {
        return true;
      }

      parent = accounts[parent].referrer;
    }

    return false;
  }

  /**
   * @dev Add an address as referrer
   * @param referrer The address would set as referrer of msg.sender
   * @return whether success to add upline
   */
  function addReferrer(address payable referrer) internal returns(bool){
    if (referrer == address(0)) {
      emit RegisteredRefererFailed(msg.sender, referrer, "Referrer cannot be 0x0 address");
      return false;
    } else if (isCircularReference(referrer, msg.sender)) {
      emit RegisteredRefererFailed(msg.sender, referrer, "Referee cannot be one of referrer uplines");
      return false;
    } else if (accounts[msg.sender].referrer != address(0)) {
      emit RegisteredRefererFailed(msg.sender, referrer, "Address have been registered upline");
      return false;
    }

    Account storage userAccount = accounts[msg.sender];
    Account storage parentAccount = accounts[referrer];

    userAccount.referrer = referrer;
    userAccount.lastActiveTimestamp = getTime();
    //parentAccount.referredCount = parentAccount.referredCount.safeAdd(1);

    emit RegisteredReferer(msg.sender, referrer);
    return true;
  }

  /**
   * @dev This will calc and pay referral to uplines instantly
   * @param value The number tokens will be calculated in referral process
   * @return the total referral bonus paid
   */
  function payReferral(uint256 value, address downlineAddress) internal returns(uint256){
    Account memory userAccount = accounts[downlineAddress];
    uint totalReferal;

    for (uint i; i < levelRate.length; i++) {
      address payable parent = userAccount.referrer;
      Account storage parentAccount = accounts[userAccount.referrer];

      if (parent == address(0)) {
        break;
      }

      // if(onlyRewardActiveReferrers && parentAccount.lastActiveTimestamp.add(secondsUntilInactive) >= getTime() || !onlyRewardActiveReferrers) {
      //   uint c = value.mul(referralBonus).div(decimals);
      //   c = c.mul(levelRate[i]).div(decimals);
      //   c = c.mul(getRefereeBonusRate(parentAccount.referredCount)).div(decimals);

      //   totalReferal = totalReferal.add(c);

      //   parentAccount.reward = parentAccount.reward.add(c);
      //   parent.transfer(c);
      //   emit PaidReferral(downlineAddress, parent, c, i + 1);
      // }

      userAccount = parentAccount;
    }

    updateActiveTimestamp(downlineAddress);
    return totalReferal;
  }


  /**
   * @dev This will calc and pay referral to uplines instantly
   * @param value The number tokens will be calculated in referral process
   * @return the total referral bonus paid
   */
  function payReferralExternally(address downlineAddress, uint256 value) internal returns(uint256){
    Account memory userAccount = accounts[downlineAddress];
    uint totalReferal;

    for (uint i; i < levelRate.length; i++) {
      address payable parent = userAccount.referrer;
      Account storage parentAccount = accounts[userAccount.referrer];

      if (parent == address(0)) {
        break;
      }

      // if(onlyRewardActiveReferrers && parentAccount.lastActiveTimestamp.add(secondsUntilInactive) >= getTime() || !onlyRewardActiveReferrers) {
      //   uint c = value.mul(referralBonus).div(decimals);
      //   c = c.mul(levelRate[i]).div(decimals);
      //   c = c.mul(getRefereeBonusRate(parentAccount.referredCount)).div(decimals);

      //   totalReferal = totalReferal.add(c);

      //   parentAccount.reward = parentAccount.reward.add(c);
      //   parent.transfer(c);
      //   emit PaidReferral(downlineAddress, parent, c, i + 1);
      // }

      userAccount = parentAccount;
    }

    updateActiveTimestamp(downlineAddress);
    return totalReferal;
  }


  /**
   * @dev Developers should define what kind of actions are seens active. By default, payReferral will active msg.sender.
   * @param user The address would like to update active time
   */
  function updateActiveTimestamp(address user) internal {
    uint timestamp = getTime();
    accounts[user].lastActiveTimestamp = timestamp;
    emit UpdatedUserLastActiveTime(user, timestamp);
  }

  function setSecondsUntilInactive(uint _secondsUntilInactive) public onlyOwner {
    secondsUntilInactive = _secondsUntilInactive;
  }

  function setOnlyRewardAActiveReferrers(bool _onlyRewardActiveReferrers) public onlyOwner {
    onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
  }
}
