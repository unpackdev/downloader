// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleChild.sol";

contract MerkleFactory is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => address[]) private tokenAirdrops;
    mapping(address => address[]) private creatorAirdrops;
    mapping(address => string) public airdropUserList;
    address[] private allAirdrops;

    IERC20 public immutable weth;
    uint256 public creatorFee = 0.03 ether;
    uint256 public claimFee = 0.003 ether;
    address payable public feeAddress;

    uint256 public minClaimPeriod = 2 hours;
    uint256 public maxClaimPeriod = 90 days;

    constructor(address _weth, address _ownerAddress, address _feeAddress) {
        weth = IERC20(_weth);
        feeAddress = payable(_feeAddress);
        _transferOwnership(_ownerAddress);
    }

    function createNewAirdrop(
        bool _isPayingInToken,
        address _token,
        uint256 _amount,
        uint256 _startDate,
        uint256 _endDate,
        string memory _url,
        bytes32 _merkleRoot
    ) external payable {
        require(_endDate > block.timestamp, "invalid endDate");
        require(_startDate < _endDate, "invalid startDate");

        uint256 duration = _endDate - _startDate;
        require(
            duration >= minClaimPeriod && duration <= maxClaimPeriod,
            "invalid duration to claim airdrop"
        );
        require(_amount > 0, "invalid amount");

        address sender = msg.sender;
        address newAirdrop = address(
            new MerkleChild(
                _token,
                payable(sender),
                feeAddress,
                _startDate,
                _endDate,
                _merkleRoot
            )
        );
        airdropUserList[newAirdrop] = _url;

        if (creatorFee > 0) {
            if (_isPayingInToken) {
                IERC20(address(weth)).safeTransferFrom(
                    sender,
                    feeAddress,
                    creatorFee
                );
            } else {
                require(msg.value >= creatorFee, "Fees not paid");
                _transferETH(feeAddress, creatorFee);
            }
        }

        allAirdrops.push(newAirdrop);
        tokenAirdrops[_token].push(newAirdrop);
        creatorAirdrops[sender].push(newAirdrop);

        if (_token == address(0)) {
            /* solhint-disable-next-line */
            _transferETH(newAirdrop, _amount);
        } else {
            IERC20(_token).safeTransferFrom(sender, newAirdrop, _amount);
        }
    }

    function setFees(
        address payable _newAddress,
        uint256 _creatorFee,
        uint256 _claimFee
    ) external onlyOwner {
        feeAddress = _newAddress;
        creatorFee = _creatorFee;
        claimFee = _claimFee;
    }

    function setClaimPeriod(uint256 min, uint256 max) external onlyOwner {
        minClaimPeriod = min;
        maxClaimPeriod = max;
    }

    function getAllTokenAirdrops(
        address _token
    ) public view returns (address[] memory) {
        return tokenAirdrops[_token];
    }

    function getAllCreatorAirdrops(
        address _creator
    ) public view returns (address[] memory) {
        return creatorAirdrops[_creator];
    }

    function getAllAirdrops() public view returns (address[] memory) {
        return allAirdrops;
    }

    function getAllAirdropsByIndex(
        uint256 startIdx,
        uint256 endIdx
    ) public view returns (address[] memory) {
        uint256 length = allAirdrops.length;
        if (length == 0) return new address[](0);

        require(startIdx < endIdx, "invalid startIdx");
        require(endIdx < allAirdrops.length, "invalid endIdx");

        address[] memory list = new address[](endIdx - startIdx + 1);
        uint256 counter = 0;

        for (uint256 i = startIdx; i <= endIdx; i++) {
            list[counter] = allAirdrops[i];
            counter++;
        }
        return list;
    }

    function _transferETH(address _recipient, uint256 _amount) internal {
        require(_amount > 0, "invalid ETH amount");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer ETH failed");
    }
}
