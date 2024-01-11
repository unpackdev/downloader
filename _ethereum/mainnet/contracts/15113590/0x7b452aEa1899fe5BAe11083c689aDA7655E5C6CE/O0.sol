pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract O0 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event Mint(uint indexed nftId);

    constructor() ERC721("O1", "O1") {}


    function minted() public view returns (uint256) {
        return _tokenIds.current();
    }

    function minter() public payable returns (uint256)
    {
        require(_tokenIds.current() <= 10000);
        require(msg.value == dropPrice, "price");
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender,  newItemId);
        _tokenIds.increment();
        emit Mint(newItemId);
        return newItemId;
    }

    function claimETH() public onlyOwner {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }

    mapping(uint256 => bool) public txchecker;

    address public matcher;
    address public matcherCandidate;
    uint256 public matcherCandidateSet;

    function setMatcherCandidate(address _matcher) public onlyOwner {
        matcher = _matcher;
        matcherCandidateSet = block.timestamp;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        setBaseURI(_uri);
    }

    function setMatcher(address _initialMatcher) public onlyOwner {
        if (matcher == address(0)) {
            matcher = _initialMatcher;
        } else {
        require(matcherCandidate != address(0));
        require(matcherCandidateSet != 0);
        require((matcherCandidateSet+cooldown) > block.timestamp);
        matcher = matcherCandidate;
        matcherCandidate = address(0);
        matcherCandidateSet = 0;
        }
    }

    function setTxOk(uint256 _id, bool _ok) public {
        require(msg.sender == matcher);
        txchecker[_id] = _ok;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(_from == address(0) || txchecker[_tokenId], "txcheck");
    }


    // ------------DEV ZONE----------------

    //  dev var, set to 3 weeks or something
    uint256 public cooldown = 20 minutes;

    // dev var, make it 0.2, now it's 0.002 !!!
    uint256 public dropPrice = 2 ether/1000;
}
