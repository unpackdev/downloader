//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

import "./IOriFactory.sol";
import "./IOriConfig.sol";
import "./OwnableUpgradeable.sol";
import "./ConsiderationStructs.sol";
import "./ConsiderationEnums.sol";
import "./ConsiderationConstants.sol";
import "./ConfigHelper.sol";
import "./OriErrors.sol";
import "./ILicenseToken.sol";
import "./IDerivativeToken.sol";
import "./TokenProxy.sol";

/**
 * @title Ori Config Center
 * @author ace
 * @notice  depoly License and Derivative NFT token.
 */
contract OriFactory is IOriFactory, OwnableUpgradeable {
    using ConfigHelper for IOriConfig;
    mapping(address => PairStruct) public originTokenPair;

    uint256 private constant _LICENSE_OPENED = 3;
    uint256 private constant _DERIVATIVE_OPENED = 5;
    uint256 private constant _OPENED = 1;

    /**
     *  Type       Enable  Binary
     *  License     N      0b010 = 2
     *  License     Y      0b011 = 3
     *  Derivative  N      0b100 = 4
     *  Derivative  Y      0b101 = 5
     *
     */
    mapping(address => uint256) private _tokens;

    function initialize() external initializer {
        __Ownable_init();
    }

    function requireRegistration(address token) external view returns (bool isLicense) {
        uint256 s = _tokens[token];
        require(s > 0 && s & _OPENED == _OPENED, "invalid status");

        isLicense = s & _LICENSE_OPENED == _LICENSE_OPENED;
        if (!isLicense) {
            require(s & _DERIVATIVE_OPENED == _DERIVATIVE_OPENED, "not dToken");
        }
    }

    function licenseToken(address originToken) external view returns (address) {
        return (originTokenPair[originToken].licenseAddress);
    }

    function derivativeToken(address originToken) external view returns (address) {
        return (originTokenPair[originToken].derivativeAddress);
    }

    /**
     * @notice enable the given nft token.
     *
     * Emits an {TokenEnabled} event.
     *
     * Requirements:
     *
     * - The nft token `token` must been created by OriFactory.
     * - The `token` must be unenabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function enableToken(address token) external onlyOwner {
        uint256 s = _tokens[token];
        require(s > 0 && s & _OPENED == 0, "invalid status");
        _tokens[token] = s ^ _OPENED;
        emit TokenEnabled(token);
    }

    /**
     * @notice disable the given nft token.
     *
     * Emits an {TokenDisabled} event.
     *
     * Requirements:
     *
     * - The `token` must be enabled.
     * - Only the administrator can call it.
     *
     * @param token  is License or Derivative contract address.
     *
     */
    function disableToken(address token) external onlyOwner {
        uint256 s = _tokens[token];
        require(s > 0 && s & _OPENED == _OPENED, "invalid status");
        _tokens[token] = s ^ _OPENED;
        emit TokenDisabled(token);
    }

    /**
     * @notice Create default license and derivative token contracts for the given NFT.
     * @dev Ori can deploy licenses and derivative contracts for every NFT contract.
     * Then each NFT's licens and derivatives will be stand-alone.
     * helping to analyz this NFT and makes the NFT managment structure clear and concise.
     *
     * Every one can call it to deploy license and derivative contracts for the given NFT.
     * but this created contracts is disabled, need the administrator to enable them.
     * them will be enabled immediately if the caller is an administrator.
     *
     * Emits a `LicenseTokenDeployed` and a `Derivative1155TokenDeployed` event.
     * And there are tow `TokenEnabled` events if the caller is an administrator.
     *
     *
     * Requirements:
     *
     * - The `originToken` must be NFT contract.
     * - Each NFT Token can only set one default license and derivative contract.
     *
     * @param originToken is the NFT contract.
     *
     */
    function createOrignPair(address originToken) external override {
        if (originTokenPair[originToken].licenseAddress != address(0)) {
            return;
        }

        // safe check, nft editor is the owner of nft.
        address nftEditor = IOriConfig(CONFIG).nftEditor();
        if (nftEditor == address(0)) revert nftEditorIsEmpty();

        {
            require(originToken.code.length > 0, "not contract");
            address lToken = _deploy(
                type(LicenseProxy).creationCode,
                keccak256(abi.encodePacked(originToken, "license"))
            );
            ILicenseToken(lToken).initialize(owner(), originToken);
            originTokenPair[originToken].licenseAddress = lToken;
            _tokens[lToken] = _LICENSE_OPENED;
            emit LicenseTokenDeployed(originToken, lToken);
        }
        {
            address derivative;
            if (IERC165(originToken).supportsInterface(ERC721_IDENTIFIER)) {
                string memory dName;
                string memory dSymbol;
                if (IERC165(originToken).supportsInterface(ERC721_METADATA_IDENTIFIER)) {
                    dName = string.concat("Derivative Of ", IERC721Metadata(originToken).name());
                    dSymbol = string.concat("DER_", IERC721Metadata(originToken).symbol());
                } else {
                    dName = "Derivative";
                    dSymbol = "DER";
                }
                derivative = _deployDerivative721(originToken, address(this), dName, dSymbol);
            } else if (IERC165(originToken).supportsInterface(ERC1155_IDENTIFIER)) {
                derivative = _deployDerivative721(originToken, address(this), "Derivative", "DER");
            } else {
                revert("not support");
            }
            originTokenPair[originToken].derivativeAddress = derivative;
        }
    }

    /**
     * @notice Create a empty derivative NFT contract
     * @dev Allow every one to call it to create derivative NFT contract.
     * Only then can Ori whitelist it. and this new contract will be enabled immediately.
     *
     * Emits a `Derivative1155TokenDeployed` event. the event parameter `originToken` is zero.
     * And there are a `TokenEnabled` event if the caller is an administrator.
     */
    function deployDerivative721(string memory dName, string memory dSymbol) external override returns (address token) {
        return _deployDerivative721(address(0), _msgSender(), dName, dSymbol);
    }

    function deployDerivative1155() public override returns (address token) {
        return _deployDerivative1155(address(0), _msgSender());
    }

    function _deployDerivative1155(address origin, address creator) private returns (address token) {
        token = _deploy(
            type(ERC1155DerivativeProxy).creationCode,
            keccak256(abi.encodePacked(creator, origin, block.number))
        );
        IDerivativeToken(token).initialize(creator, address(0), "", "");
        _tokens[token] = _DERIVATIVE_OPENED;
        emit DerivativeTokenDeployed(origin, token);
    }

    function _deployDerivative721(
        address origin,
        address creator,
        string memory dName,
        string memory dSymbol
    ) private returns (address token) {
        // salt= tx.origin + dname +dsymbol
        token = _deploy(
            type(ERC721DerivativeProxy).creationCode,
            keccak256(abi.encodePacked(creator, origin, dName, dSymbol))
        );
        IDerivativeToken(token).initialize(creator, origin, dName, dSymbol);
        _tokens[token] = _DERIVATIVE_OPENED;
        emit DerivativeTokenDeployed(origin, token);
    }

    function _deploy(bytes memory bytecode, bytes32 salt) internal returns (address addr) {
        // solhint-disable no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(addr.code.length > 0, "Failed on deploy");
    }
}
