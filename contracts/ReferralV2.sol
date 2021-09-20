pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ReferralV2 is Initializable {

    uint256 public hasInitialValue;

    function initialize() public initializer {
        hasInitialValue = 42; // set initial value in initializer
    }

    function update(uint256 newMessage) public {
      hasInitialValue = newMessage*2;
    }
}