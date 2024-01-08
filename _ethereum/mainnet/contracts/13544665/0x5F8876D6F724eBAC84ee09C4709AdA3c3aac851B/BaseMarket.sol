pragma solidity >=0.6.2 <0.8.0;
import "./SafeMath.sol";
import "./Initializable.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract BaseMarket is Ownable {
    using SafeMath for uint256;

    uint256 internal _commissionFee;
    uint256 internal _feePrecision;
    address payable internal _feeWallet;

    mapping(uint256 => bool) private _royaltySalt;

    struct RoyaltySignature {
        address nftAddr;
        uint256 tokenId;
        address payable royaltyReceiver;
        uint256 royaltyFee;
        uint256 salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    event UpdatedCommissionFee(uint256 newCommissionFee);

    event UpdatedFeeWallet(address feeWallet);

    function updateFeeWallet(address payable feeWallet) external onlyOwner {
        require(feeWallet != address(0), 'Fee wallet is the zero address');
        _feeWallet = feeWallet;
        emit UpdatedFeeWallet(_feeWallet);
    }

    /// @notice Update the commission fee
    /// @dev Update the commission fee
    /// @param newCommissionFee new commission fee
    function updateCommissionFee(uint256 newCommissionFee) public onlyOwner {
        require(newCommissionFee < _feePrecision, 'Invalid commission fee');
        _commissionFee = newCommissionFee;
        emit UpdatedCommissionFee(_commissionFee);
    }

    /// @dev Compute the fee based on the transaction price
    /// @param price total transaction price
    /// @return returnAmount amount which would be return the seller
    /// @return commissionAmount fee paid to the platform
    function _computeFee(uint256 price, uint256 royaltyFee)
        internal
        view
        returns (
            uint256 returnAmount,
            uint256 commissionAmount,
            uint256 royaltyFeeAmount
        )
    {
        commissionAmount = price.mul(_commissionFee).div(_feePrecision);
        royaltyFeeAmount = price.mul(royaltyFee).div(_feePrecision);
        returnAmount = price.sub(commissionAmount).sub(royaltyFeeAmount);
    }

    function _checkRoyaltyFeeSignature(RoyaltySignature memory sign) internal returns (bool) {
        bool isValid = false;
        if (sign.royaltyFee >= _feePrecision) return false;
        address signer = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        sign.nftAddr,
                        sign.tokenId,
                        sign.royaltyReceiver,
                        sign.royaltyFee,
                        sign.salt,
                        address(this)
                    )
                )
            ),
            sign.v,
            sign.r,
            sign.s
        );
        isValid = signer != address(0) && signer == owner() && _royaltySalt[sign.salt] == false;
        if (isValid) {
            _royaltySalt[sign.salt] = true;
        }

        return isValid;
    }
}
