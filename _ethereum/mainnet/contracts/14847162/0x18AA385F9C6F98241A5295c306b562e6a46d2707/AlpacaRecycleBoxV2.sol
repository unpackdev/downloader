// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC1155Receiver.sol";

import "./IWoolToken.sol";
import "./IWoolController.sol";
import "./ICryptoAlpaca.sol";

contract AlpacaRecycleBoxV2 is Ownable, ERC1155Receiver {
    using SafeMath for uint256;

    /* ========== STATES ========== */

    // The ALPA ERC20 token
    IWoolToken public wool;

    // Wool controller
    IWoolController public woolController;

    // Crypto alpaca contract
    ICryptoAlpaca public cryptoAlpaca;

    // number of recycled alpaca
    uint256 public totalRecycledAlpaca;

    // total minted wool
    uint256 public totalMintedWool;

    uint256 public energyMultiplier = 10;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IWoolToken _wool,
        ICryptoAlpaca _cryptoAlpaca,
        IWoolController _woolController
    ) public {
        wool = _wool;
        woolController = _woolController;
        cryptoAlpaca = _cryptoAlpaca;
    }

    /* ========== ERC1155Receiver ========== */

    /**
     * @dev onERC1155Received implementation per IERC1155Receiver spec
     */
    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256,
        bytes memory
    ) external override onlyCryptoAlpaca returns (bytes4) {
        uint256[] memory ids = _asSingletonArray(_id);
        _recycleAlpacas(_from, ids);
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev onERC1155BatchReceived implementation per IERC1155Receiver spec
     */
    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] memory _ids,
        uint256[] memory,
        bytes memory
    ) external override onlyCryptoAlpaca returns (bytes4) {
        _recycleAlpacas(_from, _ids);
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    /* ========== PRIVATE ========== */

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _recycleAlpacas(address _from, uint256[] memory _ids) private { 
        uint256 woolToMint = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            // Fetch alpaca energy and state
            (, , , , , , , , , , , uint256 energy, uint256 state) = cryptoAlpaca
                .getAlpaca(_ids[i]);
            require(state == 1, "AlpacaRecycleBox: invalid alpaca state");
            require(energy > 0, "AlpacaRecycleBox: invalid alpaca energy");
            woolToMint = woolToMint.add(energyMultiplier.mul(energy).mul(1e18));
        }

        totalRecycledAlpaca = totalRecycledAlpaca.add(_ids.length);
        totalMintedWool = totalMintedWool.add(woolToMint);

        woolController.mint(_from, woolToMint); 
    }

    /* ========== MODIFIER ========== */

    modifier onlyCryptoAlpaca() {
        require(
            msg.sender == address(cryptoAlpaca),
            "AlpacaRecycleBox: received alpaca from unauthenticated contract"
        );
        _;
    }

    /* ========== OWNER ONLY ========== */

    function setEnergyMultiplier(uint256 _value) public onlyOwner {
        energyMultiplier = _value;
    }
}
