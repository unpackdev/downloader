// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz


import "./Address.sol";
import "./NFT2ERC20RateEngine.sol";

import "./RealMath.sol";
import "./IASHRateEngineCore.sol";

abstract contract ASHRateEngineCore is NFT2ERC20RateEngine, IASHRateEngineCore {
    using Address for address;
    using RealMath for uint256;

    // contract rate classes
    mapping(address => uint8) private _contractRateClass;

    // contract token rate classes (takes precedent)
    mapping(address => mapping(uint256 => uint8)) private _contractTokenRateClass;

    bool private _enabled;

    bytes32 internal constant _erc721bytes32 = keccak256(bytes('erc721'));
    bytes32 internal constant _erc1155bytes32 = keccak256(bytes('erc1155'));

    // Class conversion variables
    uint256 private constant CLASS1_EXP = 500000000000000000;
    uint256 private constant CLASS2_EXP = 125000000000000000;
    uint256 private constant CLASS1_BASE = 1000000000000000000000;
    uint256 private constant CLASS2_BASE = 2000000000000000000;
    uint256 private constant HALVING = 5000000000000000000000000;

    /**
     * @dev Enable the rate class engine
     */
    function _updateEnabled(bool enabled) internal {
        if (_enabled != enabled) {
            _enabled = enabled;
            emit Enabled(msg.sender, enabled);
        }
    }

    /**
     * @dev Update rate class for contract
     */
    function _updateRateClass(address[] calldata contracts, uint8[] calldata rateClasses) internal {
        require(contracts.length == rateClasses.length, "ASHRateEngine: Mismatched input lengths");
        for (uint i=0; i<contracts.length; i++) {
            require(contracts[i].isContract(), "ASHRateEngine: token addresses must be contracts");
            require(rateClasses[i] < 3, "ASHRateEngine: Invalid rate class provided");
            if (_contractRateClass[contracts[i]] != rateClasses[i]) {
                _contractRateClass[contracts[i]] = rateClasses[i];
                emit ContractRateClassUpdate(msg.sender, contracts[i], rateClasses[i]);
            }
        }
    }

    /**
     * @dev Update rate class for tokens
     */
    function _updateRateClass(address[] calldata contracts, uint256[] calldata tokenIds, uint8[] calldata rateClasses) internal {
        require(contracts.length == tokenIds.length && contracts.length == rateClasses.length, "ASHRateEngine: Mismatched input lengths");
        for (uint i=0; i<contracts.length; i++) {
            require(contracts[i].isContract(), "ASHRateEngine: token addresses must be contracts");
            require(rateClasses[i] < 3, "ASHRateEngine: Invalid rate class provided");
            if (_contractTokenRateClass[contracts[i]][tokenIds[i]] != rateClasses[i]) {
                _contractTokenRateClass[contracts[i]][tokenIds[i]] = rateClasses[i];
                emit ContractTokenRateClassUpdate(msg.sender, contracts[i], tokenIds[i], rateClasses[i]);
            }
        }
    }

    /**
     * @dev See {INFT2ERC20RateEngine-getRate}.
     */
    function getRate(uint256 totalSupply, address tokenContract, uint256[] calldata args, string calldata spec) external view override returns (uint256) {
        require(_enabled, "ASHRateEngine: Disabled");

        bytes32 specbytes32 = keccak256(bytes(spec));

        if (specbytes32 == _erc721bytes32) {
            require(args.length == 1, "ASHRateEngine: Invalid arguments");
        } else if (specbytes32 == _erc1155bytes32) {
            require(args.length >= 2 && args[1] == 1, "ASHRateEngine: Only single ERC1155's supported");
        } else {
            revert("ASHRateEngine: Only ERC721 and ERC1155 currently supported");
        }

        uint8 rateClass = _contractTokenRateClass[tokenContract][args[0]];
        if (rateClass == 0) {
           rateClass = _contractRateClass[tokenContract];
        }
        require(rateClass != 0, "ASHRateEngine: Rate class for token not configured");


        if (rateClass == 1) {
            return CLASS1_EXP.rpow(totalSupply.rdiv(HALVING)).rmul(CLASS1_BASE);
        } else if (rateClass == 2) {
            return CLASS2_EXP.rpow(totalSupply.rdiv(HALVING)).rmul(CLASS2_BASE);
        }

        revert("Rate class for token not configured.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, NFT2ERC20RateEngine) returns (bool) {
        return interfaceId == type(IASHRateEngineCore).interfaceId
            || super.supportsInterface(interfaceId);
    }

}