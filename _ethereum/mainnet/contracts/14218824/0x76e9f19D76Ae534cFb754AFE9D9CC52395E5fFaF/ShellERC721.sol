//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
           This NFT collection is powered by

        ███████╗██╗  ██╗███████╗██╗     ██╗
        ██╔════╝██║  ██║██╔════╝██║     ██║
        ███████╗███████║█████╗  ██║     ██║
        ╚════██║██╔══██║██╔══╝  ██║     ██║
        ███████║██║  ██║███████╗███████╗███████╗
        ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝

           An open product framework for NFTs
            Dreamt up & built at Playgrounds

               https://heyshell.xyz
              https://playgrounds.wtf

*/

import "./ERC721Upgradeable.sol";
import "./ShellFramework.sol";

contract ShellERC721 is ShellFramework, ERC721Upgradeable {
    // for ERC-721s, mint amount must be 1
    error InvalidMintAmount();

    function initialize(
        string calldata name_,
        string calldata symbol_,
        IEngine engine,
        address owner_
    ) external initializer {
        // using the unchained variant since theres no real need to init the
        // erc165 and context stuff from openzep's 721
        __ERC721_init_unchained(name_, symbol_);

        __ShellFramework_init(engine, owner_);
    }

    // ---
    // Standard ERC721 stuff
    // ---

    function name()
        public
        view
        override(IShellFramework, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.name();
    }

    function symbol()
        public
        view
        override(IShellFramework, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.symbol();
    }

    // ---
    // Views powered by engine
    // ---

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return getTokenEngine(tokenId).getTokenURI(this, tokenId);
    }

    // ---
    // Framework functionality
    // ---

    function canSenderForkToken(address sender, uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // owner of a token can always fork
        return ownerOf(tokenId) == sender;
    }

    // ---
    // Engine functionality
    // ---

    function mint(MintEntry calldata entry) external returns (uint256) {
        if (msg.sender != address(getForkEngine(0))) {
            revert SenderNotEngine();
        }
        if (entry.amount != 1) {
            revert InvalidMintAmount();
        }

        uint256 tokenId = nextTokenId++;
        _mint(entry.to, tokenId);
        _writeMintData(tokenId, entry);

        return tokenId;
    }

    // ---
    // Introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ShellFramework, ERC721Upgradeable)
        returns (bool)
    {
        return
            ShellFramework.supportsInterface(interfaceId) ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    // ---
    // Wire up the openzep 721 hook to the engine
    // ---

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        getTokenEngine(tokenId).beforeTokenTransfer(
            msg.sender,
            from,
            to,
            tokenId,
            1
        );
    }
}
