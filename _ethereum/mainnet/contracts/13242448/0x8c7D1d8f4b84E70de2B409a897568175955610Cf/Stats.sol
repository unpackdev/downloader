// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Stats is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenCounter;
    Counters.Counter private _batchCounter;

    uint256 private _limit = 20000;
    uint256 private _fee = 20000000000000000;

    string private _uri = "https://us-central1-universal-stats-326006.cloudfunctions.net/metadata?tokenId=";

    constructor() ERC721("Universal Stats", "STT") {}

    function mint() public payable {
        require(
            _tokenCounter.current() < _limit,
            "STATS ERC721: all tokens in the batch have been minted"
        );
        require(msg.value == _fee, "STATS ERC721: incorrect fee value to mint");

        address sender = _msgSender();

        uint256 tokenId = random(
            _tokenCounter.current(),
            _batchCounter.current(),
            sender,
            block.timestamp
        );

        require(!_exists(tokenId), "STATS ERC721: token already exists");

        _tokenCounter.increment();

        _safeMint(sender, tokenId);
    }

    function releaseBatch(uint256 _newLimit, uint256 _newFee) public onlyOwner {
        require(
            _batchCounter.current() < 15,
            "STATS ERC721: all batches are released"
        );

        _batchCounter.increment();

        _limit += _newLimit;
        _fee = _newFee;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = payable(owner()).call{value: amount}("");

        require(success, "STATS ERC721: failed to send withdraw");
    }

    function changeBaseURI(string memory uri) public onlyOwner {
        _uri = uri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_uri, tokenId.toHexString(32)));
    }

    function currentLimit() public view returns (uint256) {
        return _limit;
    }

    function mintFee() public view returns (uint256) {
        return _fee;
    }

    function currentBatch() public view returns (uint256) {
        return _batchCounter.current();
    }

    function random(
        uint256 rndNonce,
        uint256 batch,
        address sender,
        uint256 timestamp
    ) private pure returns (uint256) {
        return
            ((uint256(
                keccak256(abi.encodePacked(timestamp, sender, rndNonce))
            ) / 16) * 16) + batch;
    }
}
