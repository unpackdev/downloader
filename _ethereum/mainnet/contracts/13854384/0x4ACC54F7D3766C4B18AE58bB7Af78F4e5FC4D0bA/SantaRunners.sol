// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SantaRunners is ERC721Enumerable, Ownable, ReentrancyGuard {
    address private chainRunnersContractAddress;

    // This must be equal to MAX_RUNNERS on ChainRunners.sol.
    uint256 private constant MAX_RUNNERS = 10000;

    // e.g. ipfs://QmbAQjhnBuEvsdsoSksNQdZHq9Hn9VN6oq5UWAxMPzR3Hz
    uint256 private constant TOKEN_URI_LENGTH = 53;

    // The timestamp at which the mint ends, 2022-01-01.
    uint256 private constant MINT_END_TIMESTAMP = 1640995200000;

    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("Santa Runners", "SANTARUN") {}

    function isMintFinished() internal view returns (bool) {
        return block.timestamp >= MINT_END_TIMESTAMP;
    }

    function mint(uint64 runnerID, string memory _tokenURI)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        // Ensure that runnerID is valid.
        require(0 < runnerID && runnerID <= MAX_RUNNERS, "Invalid Runner ID");
        require(
            chainRunnersContractAddress != address(0),
            "Chain Runners contract not set"
        );
        require(!isMintFinished(), "mint has finished");

        // Ensure that the address minting owns the Runner.
        IERC721Enumerable chainRunners = ERC721Enumerable(
            chainRunnersContractAddress
        );
        address owner = chainRunners.ownerOf(runnerID);
        require(owner == msg.sender, "owner mismatch");

        _safeMint(msg.sender, runnerID);
        _setTokenURI(runnerID, _tokenURI);

        return runnerID;
    }

    // The following is copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol
    // since we can't inherit from both ERC721Enumerable & ERC721URIStorage on the same contract.

    function tokenURI(uint256 runnerID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(runnerID),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[runnerID];
        return _tokenURI;
    }

    function _setTokenURI(uint256 runnerID, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(runnerID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(
            bytes(_tokenURI).length == TOKEN_URI_LENGTH,
            "Invalid token URI"
        );

        _tokenURIs[runnerID] = _tokenURI;
    }

    function _burn(uint256 runnerID) internal virtual override {
        super._burn(runnerID);

        if (bytes(_tokenURIs[runnerID]).length != 0) {
            delete _tokenURIs[runnerID];
        }
    }

    // The following are "admin" functions.

    function updateTokenURI(uint256 runnerID, string memory _tokenURI)
        external
        onlyOwner
    {
        _setTokenURI(runnerID, _tokenURI);
    }

    function burn(uint256 runnerID) external onlyOwner {
        require(
            _exists(runnerID),
            "ERC721Metadata: URI query for nonexistent token"
        );
        _burn(runnerID);
    }

    function setChainRunnersContractAddress(
        address _chainRunnersContractAddress
    ) external onlyOwner {
        chainRunnersContractAddress = _chainRunnersContractAddress;
    }

    receive() external payable {}

    function withdraw() external nonReentrant onlyOwner {
        uint256 amount = address(this).balance;
        Address.sendValue(payable(msg.sender), amount);
    }
}
