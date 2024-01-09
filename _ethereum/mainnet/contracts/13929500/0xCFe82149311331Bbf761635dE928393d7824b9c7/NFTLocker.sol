pragma solidity ^0.8.4;

import "./IERC721.sol";
contract NFTLocker {

    event ERC721Released(address indexed nft);


    uint256 private _released;
    address private immutable _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    address private  _nft;
    uint256 private immutable _tokenId;

    IERC721 private NFT;
    constructor(
        address beneficiaryAddress,
        // uint64 startTimestamp,
        uint64 durationSeconds,
        address nft,
        uint256 tokenId
        ){
        _beneficiary = beneficiaryAddress;
        // _start = startTimestamp;
        _start = uint64(block.timestamp);
        _duration = durationSeconds;
        _nft = nft;
        NFT = IERC721(_nft);
        _tokenId =tokenId;
    }

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Release the NFT if it has vested.
     */
    function release() public {
        bool releasable = _isVested(block.timestamp);
        require(releasable == true, "NFT has not vested yet.");

        NFT.transferFrom(address(this), _beneficiary, _tokenId);
        emit ERC721Released(_nft);
    }

    function _isVested(uint256 timestamp) internal view virtual returns (bool vested) {
        if (timestamp > start() + duration()) {
            return true;
        }
    }

}