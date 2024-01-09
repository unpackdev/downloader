// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Creator.sol";
import "./Feeable.sol";

struct DerivedRunnerConfig {
    address chainRunnersContractAddress;
    string contractURI;
    uint256 numTokens;
    uint256 mintPrice;
    uint256 mintStartTimestamp;
}

abstract contract DerivedRunner is
    ERC721Enumerable,
    Ownable,
    Creator,
    Feeable,
    ReentrancyGuard
{
    DerivedRunnerConfig public _derivedRunnerConfig;

    // This must be equal to MAX_RUNNERS on ChainRunners.sol.
    uint256 private constant MAX_RUNNERS = 10000;

    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    using Counters for Counters.Counter;
    Counters.Counter private _numMintedTokens;

    modifier derivedRunnerConfigSet() {
        require(
            _derivedRunnerConfig.chainRunnersContractAddress != address(0),
            "DerivedRunner: chainRunnersContractAddress not set"
        );
        require(
            bytes(_derivedRunnerConfig.contractURI).length != 0,
            "DerivedRunner: contractURI not set"
        );
        require(
            _derivedRunnerConfig.numTokens > 0,
            "DerivedRunner: numTokens not set"
        );
        require(
            _derivedRunnerConfig.mintPrice > 0,
            "DerivedRunner: mintPrice not set"
        );
        require(
            _derivedRunnerConfig.mintStartTimestamp > 0,
            "DerivedRunner: mintPrice not set"
        );
        _;
    }

    function getChainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    modifier onlyRunnerOwner(uint256 runnerId) {
        require(
            0 < runnerId && runnerId <= MAX_RUNNERS,
            "DerivedRunner: invalid runnerId"
        );

        if (getChainId() != 4) {
            IERC721Enumerable chainRunners = ERC721Enumerable(
                _derivedRunnerConfig.chainRunnersContractAddress
            );
            address owner = chainRunners.ownerOf(runnerId);
            require(
                msg.sender == owner,
                "DerivedRunner: not owner of runnerId"
            );
        }

        _;
    }

    modifier onlyOwnerOrCreator() {
        require(
            msg.sender == owner() ||
                msg.sender == _creatorConfig.creatorWalletAddress,
            "DerivedRunner: not owner or creator"
        );
        _;
    }

    function initialize(
        DerivedRunnerConfig memory derivedRunnerConfig,
        CreatorConfig memory creatorConfig,
        FeeableConfig memory feeableConfig
    ) internal {
        _derivedRunnerConfig = derivedRunnerConfig;
        _feeableConfig = feeableConfig;
        _creatorConfig = creatorConfig;
    }

    function mintToAddress(
        address to,
        uint256 runnerId,
        string memory _tokenURI
    ) internal {
        uint256 numMintedTokens = _numMintedTokens.current();
        require(
            numMintedTokens < _derivedRunnerConfig.numTokens,
            "DerivedRunner: all tokens have been minted"
        );
        require(
            block.timestamp >= _derivedRunnerConfig.mintStartTimestamp,
            "DerivedRunner: minting has not begun"
        );

        _safeMint(to, runnerId);
        _setTokenURI(runnerId, _tokenURI);
        _numMintedTokens.increment();
    }

    function mintAndRelease(uint256 runnerId, string memory _tokenURI)
        external
        payable
    {
        mint(runnerId, _tokenURI);
        sealTokenForCreator(runnerId);
    }

    function mint(uint256 runnerId, string memory _tokenURI)
        public
        payable
        onlyRunnerOwner(runnerId)
        nonReentrant
    {
        require(
            msg.value == _derivedRunnerConfig.mintPrice,
            "DerivedRunner: incorrect ETH amount"
        );

        uint256 creatorAmount = deductFees(msg.value);
        payCreator(creatorAmount);

        mintToAddress(msg.sender, runnerId, _tokenURI);
    }

    function release(uint256 runnerId, string memory _tokenURI)
        external
        onlyOwnerOrCreator
        creatorCanUpdateToken(runnerId)
        nonReentrant
    {
        _setTokenURI(runnerId, _tokenURI);
        sealTokenForCreator(runnerId);
    }

    function airdrop(
        address[] memory addresses,
        uint256[] memory runnerIds,
        string[] memory tokenURIs
    ) external onlyOwnerOrCreator nonReentrant {
        require(
            addresses.length == runnerIds.length &&
                addresses.length == tokenURIs.length,
            "DerivedRunner: length mismatch"
        );

        for (uint32 i = 0; i < addresses.length; i++) {
            address to = addresses[i];
            uint256 runnerId = runnerIds[i];
            string memory _tokenURI = tokenURIs[i];

            mintToAddress(to, runnerId, _tokenURI);
        }
    }

    function updateNumTokens(uint256 numTokens)
        external
        onlyOwnerOrCreator
        nonReentrant
    {
        require(
            numTokens > _derivedRunnerConfig.numTokens,
            "DerivedRunners: can only increase numTokens"
        );
        require(
            numTokens <= MAX_RUNNERS,
            "DerivedRunners: can not mint more than MAX_RUNNERS"
        );

        _derivedRunnerConfig.numTokens = numTokens;
    }

    function getNumTokens() external view returns (uint256) {
        return _derivedRunnerConfig.numTokens;
    }

    receive() external payable {}

    // OpenSea

    function contractURI() public view returns (string memory) {
        return _derivedRunnerConfig.contractURI;
    }

    // The following is copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol
    // since we can't inherit from both ERC721Enumerable & ERC721URIStorage on the same contract.

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(
            bytes(_tokenURI).length != 0,
            "DerivedRunner: invalid tokenURI"
        );

        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
