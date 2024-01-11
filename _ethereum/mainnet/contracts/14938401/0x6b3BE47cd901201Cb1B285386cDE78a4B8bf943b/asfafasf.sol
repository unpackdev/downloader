// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract Transfer is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    address public signer;
    mapping(uint256 => bool) recordMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }


    function checkSigner(bytes memory hash, bytes memory signature)
        private
        view
    {
        require(
            keccak256(hash).toEthSignedMessageHash().recover(signature) ==
                signer,
            "wrong signer"
        );
    }

    modifier once(uint256 id) {
        require(!recordMap[id], "already transferred");
        _;
        recordMap[id] = true;
    }

    event Transferred(
        uint256 indexed id,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 amount
    );

    function transferETH(
        address recipient,
        uint256 amount,
        uint256 id,
        bytes memory signature
    ) public nonReentrant once(id) {
        checkSigner(abi.encodePacked(recipient, amount, id), signature);
        payable(recipient).transfer(amount);
        emit Transferred(id, address(this), recipient, 0, amount);
    }

    function transferFromERC20(
        IERC20Upgradeable erc20,
        address sender,
        address recipient,
        uint256 amount,
        uint256 id,
        bytes memory signature
    ) public nonReentrant once(id) {
        checkSigner(
            abi.encodePacked(erc20, sender, recipient, amount, id),
            signature
        );
        erc20.transferFrom(sender, recipient, amount);
        emit Transferred(id, sender, recipient, 0, amount);
    }

    function safeTransferFromERC1155(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 id,
        bytes memory signature
    ) public nonReentrant once(id) {
        checkSigner(abi.encodePacked(from, to, tokenAddress, tokenId, amount, id), signature);
        IERC1155Upgradeable(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "");
        emit Transferred(id, from, to, tokenId, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    receive() external payable {}
}
