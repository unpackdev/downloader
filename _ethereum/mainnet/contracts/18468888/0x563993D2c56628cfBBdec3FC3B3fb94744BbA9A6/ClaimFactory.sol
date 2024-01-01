// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Claim.sol";
import "./emitter.sol";
import "./proxy.sol";
import "./AccessControl.sol";
import "./Initializable.sol";

contract ClaimFactory is AccessControl, Initializable {
    using SafeERC20 for IERC20;

    uint public claimPrice;
    uint public claimFee;

    address private _emitterContract;
    address private _owner;

    address private _claimImplementation;

    string private _networkId;

    function initialize(
        address claimImplementation,
        uint _claimFee,
        uint _claimPrice,
        string calldata networkId
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _claimImplementation = claimImplementation;
        claimFee = _claimFee;
        claimPrice = _claimPrice;
        _owner = msg.sender;
        _networkId = networkId;
    }

    event NewClaimContract(address _newClaimContract);

    /// @notice This function takes claim settings as input and deploys a new claim contract
    /// @dev Caller needs to pay claim price
    /// @param _claimSettings Settings of claim to be deployed
    /// @param totalWallets Number of wallets (for pro-rata)
    /// @param blockNumber Block number (for pro-rata)
    /// @param whitelistNetwork Network string
    function deployClaimContract(
        ClaimSettings memory _claimSettings,
        uint256 totalWallets,
        uint256 blockNumber,
        string calldata whitelistNetwork
    ) external payable {
        if (msg.value != claimPrice) revert InvalidAmount();

        if (_claimSettings.airdropToken == address(0)) revert InvalidAddress();

        if (_claimSettings.walletAddress == address(0)) revert InvalidAddress();

        if (_claimSettings.startTime > _claimSettings.endTime)
            revert InvalidTime();

        if (_claimSettings.claimAmountDetails.maxClaimable == 0)
            revert InvalidAmount();

        bytes memory _initializer = abi.encodeWithSignature(
            "initialize(address,(string,address,address,address,address,uint256,uint256,uint256,uint256,bool,bool,bytes32,uint8,(uint256,uint256)),address,address)",
            msg.sender,
            _claimSettings,
            address(this),
            _emitterContract
        );

        //Deploying new claim contract
        address newClaimContract = address(
            new ProxyContract(_claimImplementation, _owner, _initializer)
        );

        //Depositing tokens in claim contract if token is ERC20 and hasAllowanceMechanism = false
        if (!_claimSettings.hasAllowanceMechanism) {
            IERC20(_claimSettings.airdropToken).safeTransferFrom(
                msg.sender,
                newClaimContract,
                _claimSettings.claimAmountDetails.totalClaimAmount
            );
        }

        emit NewClaimContract(newClaimContract);
        ClaimEmitter(_emitterContract).claimContractDeployed(
            _claimSettings,
            totalWallets,
            blockNumber,
            whitelistNetwork,
            _networkId,
            address(newClaimContract)
        );
    }

    /// @notice This function sets the address of emitter contract
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _emitter Address of emitter contract
    function setEmitter(
        address _emitter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _emitterContract = _emitter;
    }

    /// @notice This function is used to update price of claim
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _newClaimPrice Updated claim price
    function changeClaimPrice(
        uint _newClaimPrice
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimPrice = _newClaimPrice;
    }

    /// @notice This function is used to update fee of claim
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _newClaimFee Updated claim fee
    function changeClaimFee(
        uint _newClaimFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimFee = _newClaimFee;
    }

    /// @notice This function is used to change address of claim implementation
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _newClaimImplementation Address of new implementation
    function changeClaimImplementation(
        address _newClaimImplementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimImplementation = _newClaimImplementation;
    }

    /// @notice This function is used to set address of disburse contract in emitter
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _disburse Address of disburse
    function setDisburse(
        address _disburse
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ClaimEmitter(_emitterContract).grantDisburseRole(_disburse);
    }

    /// @notice This function is used to withdraw funds collected through claim deployments
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _receiver Address of receiver
    /// @param _amount Amount to withdraw
    function withdrawFunds(
        address _receiver,
        uint _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success, "Withdraw failed");
    }

    receive() external payable {}
}
