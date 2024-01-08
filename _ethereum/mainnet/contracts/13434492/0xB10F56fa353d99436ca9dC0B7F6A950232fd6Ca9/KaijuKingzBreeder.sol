// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IKaijuKingz.sol";
import "./IRWaste.sol";

contract KaijuKingzBreeder is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    IKaijuKingz public kaiju;
    address public rwaste;

    uint256 public breederId;
    bool public hasBreeder;

    uint256 public fee;
    mapping(address => bool) public whitelist;

    uint256 public constant FUSION_PRICE = 750 ether;
    uint256 public immutable genesisCount;

    event Breed(uint256 babyId);

    constructor(address _kaiju) {
        require(_kaiju != address(0), "0");
        kaiju = IKaijuKingz(_kaiju);
        rwaste = getRWaste();
        genesisCount = kaiju.maxGenCount();
        fee = 0.1 ether;
    }

    function breed(uint256 _kaijuId, uint256 _amount) external payable {
        require(_amount > 0, "0");
        require(msg.value == fee * _amount, "wrong ETH amount");
        _breed(_kaijuId, _amount);
    }

    function breedFree(uint256 _kaijuId, uint256 _amount) external {
        require(_amount > 0, "0");
        require(whitelist[msg.sender], "not in whitelist");
        _breed(_kaijuId, _amount);
    }

    function depositBreeder(uint256 _tokenId) external onlyOwner {
        require(!hasBreeder, "already has breeder");
        kaiju.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        breederId = _tokenId;
        hasBreeder = true;
    }

    function withdrawBreeder() external onlyOwner {
        require(hasBreeder, "no breeder");
        kaiju.safeTransferFrom(address(this), msg.sender, breederId, "");
        delete breederId;
        hasBreeder = false;
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(_amount > 0, "0");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    function claimRWaste() external onlyOwner {
        IRWaste(rwaste).claimReward();
        uint256 amount = IERC20(rwaste).balanceOf(address(this));
        IERC20(rwaste).safeTransfer(msg.sender, amount);
    }

    function syncRWaste() external onlyOwner {
        address newRwaste = getRWaste();
        require(newRwaste != rwaste, "same");
        rwaste = newRwaste;
    }

    function updateFee(uint256 _fee) external onlyOwner {
        require(fee != _fee, "same");
        fee = _fee;
    }

    function updateWhitelist(
        address[] calldata addresses,
        bool[] calldata values
    ) external onlyOwner {
        require(addresses.length == values.length, "invalid inputs");
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = values[i];
        }
    }

    function getRWaste() public view returns (address) {
        return kaiju.RWaste();
    }

    function getNextBabyId() public view returns (uint256) {
        return genesisCount + kaiju.babyCount();
    }

    function _breed(uint256 _kaijuId, uint256 _amount) internal {
        require(hasBreeder, "no breeder");
        assert(_amount > 0);

        kaiju.safeTransferFrom(msg.sender, address(this), _kaijuId, "");

        IERC20(rwaste).safeTransferFrom(
            msg.sender,
            address(this),
            FUSION_PRICE * _amount
        );

        for (uint256 i = 0; i < _amount; i++) {
            uint256 babyId = getNextBabyId();
            kaiju.fusion(breederId, _kaijuId);
            kaiju.safeTransferFrom(address(this), msg.sender, babyId, "");
            emit Breed(babyId);
        }

        kaiju.safeTransferFrom(address(this), msg.sender, _kaijuId, "");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
