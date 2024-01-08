// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.4;

import "./CToken.sol";
import "./Comptroller.sol";
import "./Interfaces.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/// @dev This contract holds the addresses and information related
/// to all the relevant contracts.
/// @dev This contract should be used by all other contracts to get
/// the latest contract address information.
/// @dev This contract serves as the single source of truth for all
/// kCompound contracts.
contract CompoundVars is Ownable {
    /// @notice weth token address
    address public weth;

    /// @notice address of the Compound comptroller contract.
    Comptroller public comptroller;

    /// @notice address of the KeeperDAO's kComptroller contract.
    IKComptroller public kComptroller;

    /// @notice address of the KeeperDAO's kCompound contract.
    ERC721 public kCompound;

    /// @notice list of supported cERC20s.
    CErc20[] public cERC20s;

    /// @notice cEther contract address.
    CEther public cEther;

    /// @notice address of the KeeperDAO's liquidityPool contract.
    address payable public jitu;

    /// @notice underlying address to cERC20 token map.
    mapping (address=>CErc20) public cTokenMap;

    address[] _cTokens;

    constructor (
        address _weth, 
        Comptroller _comptroller, 
        CEther _cEther, 
        CErc20[] memory _cERC20s,
        IKComptroller _kComptroller, 
        address payable _jitu,
        ERC721 _kCompound
    ) {
        require(_weth != address(0), "CompoundMigrator: WETH should not be 0x0");
        require(_comptroller != Comptroller(0), "CompoundMigrator: Comptroller should not be 0x0");
        require(_cEther != CEther(0), "CompoundMigrator: cEther should not be 0x0");
        weth = _weth;
        comptroller = _comptroller;
        cEther = _cEther;
        kComptroller = _kComptroller;
        jitu = _jitu;
        kCompound = _kCompound;

        _cTokens.push(address(_cEther));
        for (uint16 i = 0; i < _cERC20s.length; i++) {
            addCERC20(_cERC20s[i]);
        }
    }

    /// @notice allows the owner of this contract to
    /// update the JITU.
    function updateJITU(address payable _newJITU) external onlyOwner {
        require(_newJITU != address(0), "CompoundVars: JITU cannot be 0x0");
        jitu = _newJITU;
    }

    /// @notice allows the owner of this contract to
    /// update the KComptroller.
    function updateKComptroller(IKComptroller _kComptroller) external onlyOwner {
        require(_kComptroller != IKComptroller(0), "CompoundVars: KComptroller cannot be 0x0");
        kComptroller = _kComptroller;
    }

    /// @notice allows the owner of this contract to
    /// update the KCompound.
    function updateKCompound(ERC721 _kCompound) external onlyOwner {
        require(_kCompound != ERC721(0), "CompoundVars: KCompound cannot be 0x0");
        kCompound = _kCompound;
    }

    /// @notice allows the owner of this contract to
    /// update the Comptroller.
    function updateComptroller(Comptroller _comptroller) external onlyOwner {
        require(_comptroller != Comptroller(0), "CompoundVars: Comptroller cannot be 0x0");
        comptroller = _comptroller;
    }

    /// @notice allows the owner of add additional
    /// CERC20 tokens.
    function addCERC20(CErc20 _newCERC20) public onlyOwner {
        require(_newCERC20 != CErc20(0), "CompoundVars: CErc20 cannot be 0x0");
        require(_newCERC20.underlying() != address(0), "CompoundVars: CErc20's underlying address cannot be 0x0");
        require(cTokenMap[_newCERC20.underlying()] == CErc20(0), "CompoundVars: CErc20 already listed");

        cERC20s.push(_newCERC20);
        cTokenMap[_newCERC20.underlying()] = _newCERC20;
        _cTokens.push(address(_newCERC20));
    }   

    /// @notice return the list of supported cTokens
    function cTokens() external view returns (address[] memory) {
        return _cTokens;
    }

    /// @notice returns the cToken contract for the given underlying token.
    ///
    /// @param _token the underlying token address.
    ///
    /// @return corresponding cToken address for the given token.
    function cTokenWrapper(address _token) external view returns (CToken) {
        require(_token != address(0), "CompoundVars: token cannot be 0x0");
        CToken cToken;
        if (weth == _token) {
            cToken = cEther;
        } else {
            cToken = cTokenMap[_token];
        }
        require(cToken != CToken(0), "CompoundVars: unsupported token");
        return cToken;
    }
}