pragma solidity 0.5.17;

import "./SafeMath.sol";
import "./TBTCDepositToken.sol";
import "./FeeRebateToken.sol";
import "./TBTCToken.sol";
import "./TBTCConstants.sol";
import "./Deposit.sol";
import "./TBTCSystemAuthority.sol";

/// @title  Vending Machine
/// @notice The Vending Machine swaps TDTs (`TBTCDepositToken`)
///         to TBTC (`TBTCToken`) and vice versa.
/// @dev    The Vending Machine should have exclusive TBTC and FRT (`FeeRebateToken`) minting
///         privileges.
contract VendingMachine is TBTCSystemAuthority{
    using SafeMath for uint256;

    TBTCToken tbtcToken;
    TBTCDepositToken tbtcDepositToken;
    FeeRebateToken feeRebateToken;

    constructor(address _systemAddress)
        TBTCSystemAuthority(_systemAddress)
    public {}

    /// @notice Set external contracts needed by the Vending Machine.
    /// @dev    Addresses are used to update the local contract instance.
    /// @param _tbtcToken        TBTCToken contract. More info in `TBTCToken`.
    /// @param _tbtcDepositToken TBTCDepositToken (TDT) contract. More info in `TBTCDepositToken`.
    /// @param _feeRebateToken   FeeRebateToken (FRT) contract. More info in `FeeRebateToken`.
    function setExternalAddresses(
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken
    ) public onlyTbtcSystem {
        tbtcToken = _tbtcToken;
        tbtcDepositToken = _tbtcDepositToken;
        feeRebateToken = _feeRebateToken;
    }

    /// @notice Determines whether a deposit is qualified for minting TBTC.
    /// @param _depositAddress The address of the deposit
    function isQualified(address payable _depositAddress) public view returns (bool) {
        return Deposit(_depositAddress).inActive();
    }

    /// @notice Burns TBTC and transfers the tBTC Deposit Token to the caller
    ///         as long as it is qualified.
    /// @dev    We burn the lotSize of the Deposit in order to maintain
    ///         the TBTC supply peg in the Vending Machine. VendingMachine must be approved
    ///         by the caller to burn the required amount.
    /// @param _tdtId ID of tBTC Deposit Token to buy.
    function tbtcToTdt(uint256 _tdtId) public {
        require(tbtcDepositToken.exists(_tdtId), "tBTC Deposit Token does not exist");
        require(isQualified(address(_tdtId)), "Deposit must be qualified");

        uint256 depositValue = Deposit(address(uint160(_tdtId))).lotSizeTbtc();
        require(tbtcToken.balanceOf(msg.sender) >= depositValue, "Not enough TBTC for TDT exchange");
        tbtcToken.burnFrom(msg.sender, depositValue);

        // TODO do we need the owner check below? transferFrom can be approved for a user, which might be an interesting use case.
        require(tbtcDepositToken.ownerOf(_tdtId) == address(this), "Deposit is locked");
        tbtcDepositToken.transferFrom(address(this), msg.sender, _tdtId);
    }

    /// @notice Transfer the tBTC Deposit Token and mint TBTC.
    /// @dev    Transfers TDT from caller to vending machine, and mints TBTC to caller.
    ///         Vending Machine must be approved to transfer TDT by the caller.
    /// @param _tdtId ID of tBTC Deposit Token to sell.
    function tdtToTbtc(uint256 _tdtId) public {
        require(tbtcDepositToken.exists(_tdtId), "tBTC Deposit Token does not exist");
        require(isQualified(address(_tdtId)), "Deposit must be qualified");

        tbtcDepositToken.transferFrom(msg.sender, address(this), _tdtId);

        // If the backing Deposit does not have a signer fee in escrow, mint it.
        Deposit deposit = Deposit(address(uint160(_tdtId)));
        uint256 signerFee = deposit.signerFee();
        uint256 depositValue = deposit.lotSizeTbtc();

        if(tbtcToken.balanceOf(address(_tdtId)) < signerFee) {
            tbtcToken.mint(msg.sender, depositValue.sub(signerFee));
            tbtcToken.mint(address(_tdtId), signerFee);
        }
        else{
            tbtcToken.mint(msg.sender, depositValue);
        }

        // owner of the TDT during first TBTC mint receives the FRT
        if(!feeRebateToken.exists(_tdtId)){
            feeRebateToken.mint(msg.sender, _tdtId);
        }
    }

    // WRAPPERS

    /// @notice Qualifies a deposit and mints TBTC.
    /// @dev User must allow VendingManchine to transfer TDT.
    function unqualifiedDepositToTbtc(
        address payable _depositAddress,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        Deposit _d = Deposit(_depositAddress);
        require(
            _d.provideBTCFundingProof(
                _txVersion,
                _txInputVector,
                _txOutputVector,
                _txLocktime,
                _fundingOutputIndex,
                _merkleProof,
                _txIndexInBlock,
                _bitcoinHeaders
            ),
            "failed to provide funding proof");

        tdtToTbtc(uint256(_depositAddress));
    }

    /// @notice Redeems a Deposit by purchasing a TDT with TBTC for _finalRecipient,
    ///         and using the TDT to redeem corresponding Deposit as _finalRecipient.
    ///         This function will revert if the Deposit is not in ACTIVE state.
    /// @dev Vending Machine transfers TBTC allowance to Deposit.
    /// @param  _depositAddress     The address of the Deposit to redeem.
    /// @param  _outputValueBytes   The 8-byte Bitcoin transaction output size in Little Endian.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The deposit redeemer. This address will receive the TDT.
    function tbtcToBtc(
        address payable _depositAddress,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public {
        require(tbtcDepositToken.exists(uint256(_depositAddress)), "tBTC Deposit Token does not exist");
        Deposit _d = Deposit(_depositAddress);

        tbtcToken.burnFrom(msg.sender, _d.lotSizeTbtc());
        tbtcDepositToken.approve(_depositAddress, uint256(_depositAddress));

        uint256 tbtcOwed = _d.getOwnerRedemptionTbtcRequirement(msg.sender);

        if(tbtcOwed != 0){
            tbtcToken.transferFrom(msg.sender, address(this), tbtcOwed);
            tbtcToken.approve(_depositAddress, tbtcOwed);
        }

        _d.transferAndRequestRedemption(_outputValueBytes, _redeemerOutputScript, _finalRecipient);
    }
}
