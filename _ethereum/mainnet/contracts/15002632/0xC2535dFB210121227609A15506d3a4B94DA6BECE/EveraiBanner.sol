// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";

interface IEveraiMemoryCore is IERC721A {
    function mint(address to, uint256 quantity) external;
}

contract EveraiBanner is ERC721A, Ownable, ReentrancyGuard {
    address public authorizedBurnContractAddress;
    address public authorizedUpgradeContractAddress;

    string private _baseTokenURI;

    uint256[40] claimedBitMap;
    bool public claimActive;

    mapping(uint256 => uint8) public levels; // 0 - 255
    mapping(uint256 => uint16) public types; // 0 - 65 535

    IERC721A public immutable everaiDuo;
    IEveraiMemoryCore public everaiMemoryCore;

    constructor(address everaiDuoAddress, address everaiMemoryCoreAddress)
        ERC721A("EveraiBanner", "EveraiBanner")
    {
        everaiDuo = IERC721A(everaiDuoAddress);
        everaiMemoryCore = IEveraiMemoryCore(everaiMemoryCoreAddress);
    }

    function setEveraiMemoryCardAddress(address everaiMemoryCoreAddress)
        external
        onlyOwner
    {
        everaiMemoryCore = IEveraiMemoryCore(everaiMemoryCoreAddress);
    }

    function setAuthorizedUpgradeContractAddress(
        address authorizedUpgradeContractAddress_
    ) external onlyOwner {
        authorizedUpgradeContractAddress = authorizedUpgradeContractAddress_;
    }

    function setAuthorizedBurnContractAddress(
        address authorizedBurnContractAddress_
    ) external onlyOwner {
        authorizedBurnContractAddress = authorizedBurnContractAddress_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _toString(types[tokenId]),
                        "/",
                        _toString(levels[tokenId])
                    )
                )
                : "";
    }

    function setClaimActive(bool claimActive_) external onlyOwner {
        claimActive = claimActive_;
    }

    function isClaimed(uint256 tokenId) public view returns (bool) {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 tokenId) internal {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(uint256[] memory tokenIds) public nonReentrant {
        require(claimActive, "Claim is not active.");

        uint256 numTokensClaimed;
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address owner = everaiDuo.ownerOf(tokenId);
            require(owner == msg.sender, "Owner does not match");
            if (!isClaimed(tokenId)) {
                _setClaimed(tokenId);
                numTokensClaimed++;
            }
        }

        everaiMemoryCore.mint(msg.sender, numTokensClaimed);
        _safeMint(msg.sender, numTokensClaimed);
    }

    function upgrade(uint256 tokenId, uint16 memoryCoreType) external {
        require(
            msg.sender == owner() ||
                msg.sender == authorizedUpgradeContractAddress,
            "Authorization required"
        );

        types[tokenId] = memoryCoreType;
        levels[tokenId] = levels[tokenId] + 1;
    }

    function burn(uint256 tokenId) external {
        require(
            authorizedBurnContractAddress == msg.sender,
            "Authorization required"
        );

        _burn(tokenId);
    }
}
