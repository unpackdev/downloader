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
        matcherCandidate = _matcher;
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

    function openMatch(uint256 _id, address _xored, address _conduit) public {
        require(msg.sender == matcher);
        txchecker[_id] = true;
        _transfer(_xored, matcher, _id);
        // move to one-off (to setMatcher()?)
        _setApprovalForAll(matcher, _conduit, true);
    }

    function restoreMatch(uint256 _id, address _xoredToBuyer, address _xored) public {
        require(msg.sender == matcher);
        _transfer(_xoredToBuyer, _xored, _id);
    }

    function closeMatch(uint256 _id, address _xored) public {
        require(msg.sender == matcher);
        _transfer(matcher, _xored, _id);
        txchecker[_id] = false;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(_from == address(0) || txchecker[_tokenId], "make offer");
    }


    // ------------DEV ZONE----------------

    //  dev var, set to 3 weeks or something
    uint256 public cooldown = 5 minutes;

    // dev var, make it 0.2, now it's 0.002 !!!
    uint256 public dropPrice = 2 ether/1000;


    //TODO redeploy - setmatchercandidate was wrong, was setting matcher directly not candidate
    //TODO check block timestamp in matcherCandidateSet and setting logic around this timestamp
}
