// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// ============ Imports ============
import "./ERC721Delegated.sol";
import "./ERC721Base.sol";
import "./CountersUpgradeable.sol";

/// @notice Bad Bunny Virus Contract
/// @author iain @isiain
contract BadBunnyVirus is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter currentTokenId;

    /// @notice used to track the generation depth of the bunny
    mapping(uint256 => uint256) public lastDepth;

    /// @notice delegate constructor for gwei saving nft impl
    constructor(address baseFactory)
        ERC721Delegated(
            baseFactory,
            "Bad Bunny",
            "BBUNNY",
            ConfigSettings({
                royaltyBps: 1000,
                uriBase: "https://autumn-wood.isiain.workers.dev/",
                uriExtension: "",
                hasTransferHook: true
            })
        )
    {
        currentTokenId.increment();
    }

    /// @notice admin origin original mint: only works when contract is first deployed
    function mintOrigin() public onlyOwner {
        require(currentTokenId.current() == 1);
        _mint(msg.sender, 0);
    }

    /// @notice allows admint to update the baseuri
    function setBaseURI(string memory baseUri) public onlyOwner {
        _setBaseURI(baseUri, "");
    }

    /// @notice the magic happens here for the spawning bit
    function _beforeTokenTransfer(
        address from,
        address,
        uint256 tokenId
    ) public {
        if (from != address(0x0)) {
            _mint(from, currentTokenId.current());
            uint256 atDepth = lastDepth[tokenId];
            lastDepth[currentTokenId.current()] = atDepth;
            lastDepth[tokenId] = atDepth + 1;
            currentTokenId.increment();
        }
    }
}
