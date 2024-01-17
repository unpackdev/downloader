//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract Claim is Ownable {
    using SafeERC20 for IERC20;

    // IERC20 public burnToken;
    IERC20 public claimToken;

    uint public conversionRatio; // eg - 1e7 ymeme = 1000e18 nymeme -> conversionRatio = 100000
    uint public burnDecimal;
    uint public claimDecimal;

    mapping (address => ClaimInfo) public claimInfo;

    struct ClaimInfo {
        uint amount;
        bool exists;
     }

    constructor(address _claimToken) {
        // burnToken = IERC20(_burnToken);
        claimToken = IERC20(_claimToken);
        burnDecimal = 9;
        claimDecimal = 18;
    }

    function claim() external {
        require(claimInfo[msg.sender].exists == true, "Claim: Already claimed or no claim");
        claimInfo[msg.sender].exists = false;
        claimToken.safeTransfer(msg.sender, claimInfo[msg.sender].amount);
    }

    // function claim(uint256 amount) external {
    //     burnToken.safeTransferFrom(msg.sender, address(this), amount);
    //     uint256 claimAmount = _calcClaimAmount(amount);
    //     claimToken.safeTransfer(msg.sender, claimAmount);
    // }

    // function _calcClaimAmount(uint _burnAmount) internal view returns (uint256) {
    //     return _burnAmount * 10**claimDecimal * conversionRatio / (100 * 10**burnDecimal);
    // }

    function addWhitelistedUsers(address[] calldata _users, uint[] calldata _amounts) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            claimInfo[_users[i]] = ClaimInfo(_amounts[i], true);
        }
    }

    // function setBurnToken(address _burnToken) external onlyOwner {
    //     burnToken = IERC20(_burnToken);
    // }

    function setClaimToken(address _claimToken) external onlyOwner {
        claimToken = IERC20(_claimToken);
    }

    // function setConversionRatio(uint _conversionRatio) external onlyOwner {
    //     conversionRatio = _conversionRatio;
    // }

    function withdraw(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}