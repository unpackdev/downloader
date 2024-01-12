pragma solidity ^0.8.6;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";


// █▀█ █▄░█ █░░ █▄█ █░█ █▀█ █▀ ░ ▀▄▀ █▄█ ▀█
// █▄█ █░▀█ █▄▄ ░█░ █▄█ █▀▀ ▄█ ▄ █░█ ░█░ █▄

// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋┏┓
// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋┏┛┗┓╋╋╋╋╋╋┏┛┗┓
// ┏━━┳━┳┳━━┳┳━┓┏━━┫┃╋┏━━┳━━┳━╋┓┏╋━┳━━┳━┻┓┏╋━━┓
// ┃┏┓┃┏╋┫┏┓┣┫┏┓┫┏┓┃┃╋┃┏━┫┏┓┃┏┓┫┃┃┏┫┏┓┃┏━┫┃┃━━┫
// ┃┗┛┃┃┃┃┗┛┃┃┃┃┃┏┓┃┗┓┃┗━┫┗┛┃┃┃┃┗┫┃┃┏┓┃┗━┫┗╋━━┃
// ┗━━┻┛┗┻━┓┣┻┛┗┻┛┗┻━┛┗━━┻━━┻┛┗┻━┻┛┗┛┗┻━━┻━┻━━┛
// ╋╋╋╋╋╋┏━┛┃
// ╋╋╋╋╋╋┗━━┛

// █▄░█ █▀▀ ▀█▀ █▀   █░░ █▀█ █▀▀ █▄▀ █▀▀ █▀▄   ▀█▀ █▀█   █▀▀ █▀█   █░█ █▀█
// █░▀█ █▀░ ░█░ ▄█   █▄▄ █▄█ █▄▄ █░█ ██▄ █▄▀   ░█░ █▄█   █▄█ █▄█   █▄█ █▀▀

// ONLYUPS.XYZ
// ORIGINAL CONTRACTS
// NFTS LOCKED TO GO UP

// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA

contract OnlyUps is ERC721Enumerable, Ownable {

    event Mint(uint indexed nftId);

    constructor() ERC721("OnlyUps", "OnlyUps") {}

    bool public mintOpen;

    string public metaBase;

    function minter() public payable returns (uint256)
    {
        require(totalSupply() < 10000);
        require(msg.value == dropPrice, "price");
        require(mintOpen || msg.sender == owner());
        uint256 id = totalSupply();
        _mint(msg.sender, id);
        emit Mint(id);
        return id;
    }

    function distribute() public onlyOwner {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }

    function setMint(bool _isOpen) public onlyOwner {
        mintOpen = _isOpen;
    }

    mapping(uint256 => bool) public txchecker;

    address public matcher;
    address public matcherCandidate;
    uint256 public matcherCandidateSet;

    function setMatcherCandidate(address _matcher) public onlyOwner {
        matcherCandidate = _matcher;
        matcherCandidateSet = block.timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metaBase;
    }

    function setBaseURI(string memory _base) external onlyOwner {
        metaBase = _base;
    }

    function setMatcher(address _initialMatcher) public onlyOwner {
        if (matcher == address(0)) {
            matcher = _initialMatcher;
        } else {
        require(matcherCandidate != address(0));
        require(matcherCandidateSet != 0);
        require((matcherCandidateSet+cooldown) < block.timestamp);
        matcher = matcherCandidate;
        matcherCandidate = address(0);
        matcherCandidateSet = 0;
        }
    }

    function openMatch(uint256 _id, address _xored, address _conduit) public {
        require(msg.sender == matcher);
        txchecker[_id] = true;
        _transfer(_xored, matcher, _id);
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


    uint256 public cooldown = 21 days;
    uint256 public dropPrice = 2 ether/10;

}
