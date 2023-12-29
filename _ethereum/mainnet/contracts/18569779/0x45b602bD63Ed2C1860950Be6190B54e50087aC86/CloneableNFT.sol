pragma solidity 0.8.16;

import "./Cloneable.sol";
import "./SafeERC20.sol";
import "./MintVoucherVerification.sol";
import "./Helper.sol";

contract CloneableNFT is Cloneable, CommonAccess, CommonSoulBound, MintVoucherVerification {
    using SafeERC20 for IERC20;

    uint128 public currentSupply;
    uint128 public maxSupply;
    bool public baseURIPermanent;
    string public contractURI;
    string public baseURI;

    string internal _tokenName;
    string internal _tokenSymbol;

    event ContractURIUpdated(string prevURI, string newURI);
    event MaxSupplyUpdated(uint128 oldMaxSupply, uint128 newMaxSupply);
    event BaseURIUpdated(string newlyUpdatedURI);
    event PermanentURI(string _value, uint256 indexed _id);
    event TokenMaxSupplyUpdated(uint256 indexed tokenId, uint128 oldMaxSupply, uint128 newMaxSupply);

    /***********************************************|
    |               Internal                        |
    |______________________________________________*/
    function _initialize(
        address admin,
        address owner_,
        address signer,
        uint128 maxSupply_,
        bool soulBound_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory baseContractURI_
    ) internal virtual {
        CommonAccess(address(this)).initialize(admin, owner_);
        CommonSoulBound(address(this)).initialize(soulBound_);
        MintVoucherVerification(address(this)).initialize(signer);

        // initialization workarounds
        _tokenName = name_;
        _tokenSymbol = symbol_;

        // initialize state variables
        if (maxSupply_ == 0) {
            revert CommonError.ValueCannotBeZero();
        }

        if (bytes(baseURI_).length > 0) {
            baseURI = baseURI_;
            emit BaseURIUpdated(baseURI_);
        }

        maxSupply = maxSupply_;
        contractURI = CommonFunction._defaultContractURI(baseContractURI_);
    }
}
