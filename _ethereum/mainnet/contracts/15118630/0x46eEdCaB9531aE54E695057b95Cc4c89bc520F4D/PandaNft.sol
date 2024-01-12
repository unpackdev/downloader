// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

error PandaNft__CountZero();
error PandaNft__MaxPerAccountReached();
error PandaNft__MaxPerAccountPresaleReached();
error PandaNft__MaxSupplyReached();
error PandaNft__NotPresaleState();
error PandaNft__NotPublicSaleState();
error PandaNft__NotInWhitelist();
error PandaNft__EthNotEnough();

contract PandaNft is ERC721, Ownable {
    // sale state
    enum State {
        Pending,
        Presale,
        PublicSale,
        Finished
    }

    // presale mint event
    event PresaleMint(address account);

    // public sale mint event
    event Mint(address account);

    // withdraw event
    event Withdraw(address account);

    // sale state
    State public state = State.Pending;

    uint256 private tokenCounter;

    // max supply
    uint256 public immutable maxSupply;

    // max token count per account
    uint256 public immutable maxPerAccount;

    // max token count per account in presale stage
    uint256 public immutable maxPerAccountPresale;

    // max free token count
    uint256 public immutable maxFreeCount;

    // mint price
    uint256 public immutable price;

    // presale whitelist
    mapping(address => bool) public whitelist;

    // base token URI
    string public baseURI;

    constructor(
        uint256 _maxSupply,
        uint256 _maxPerAccount,
        uint256 _maxPerAccountPresale,
        uint256 _maxFreeCount,
        uint256 _price,
        string memory _uri
    ) ERC721("PandaNft", "PN") {
        maxSupply = _maxSupply;
        maxPerAccount = _maxPerAccount;
        maxPerAccountPresale = _maxPerAccountPresale;
        maxFreeCount = _maxFreeCount;
        price = _price;
        baseURI = _uri;
    }

    function addWhitelist(address[] memory _whitelist) public onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; ++i) {
            whitelist[_whitelist[i]] = true;
        }
    }

    // function addWhitelist(address account) public onlyOwner {
    //     whitelist[account] = true;
    // }

    function removeWhitelist(address[] memory _whitelist) public onlyOwner {
        for (uint256 i = 0; i < _whitelist.length; ++i) {
            delete whitelist[_whitelist[i]];
        }
    }

    // total supply
    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    // set the state
    function setState(uint8 _state) public onlyOwner {
        state = State(_state);
    }

    // base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // set base token URI
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    // presale mint
    function presaleMint() public payable {
        if (state != State.Presale) {
            revert PandaNft__NotPresaleState();
        }

        if (totalSupply() >= maxSupply) {
            revert PandaNft__MaxSupplyReached();
        }

        if (balanceOf(msg.sender) >= maxPerAccountPresale) {
            revert PandaNft__MaxPerAccountPresaleReached();
        }

        if (!whitelist[msg.sender]) {
            revert PandaNft__NotInWhitelist();
        }

        if (totalSupply() >= maxFreeCount && msg.value < price) {
            revert PandaNft__EthNotEnough();
        }

        ++tokenCounter;
        _safeMint(msg.sender, tokenCounter);

        emit PresaleMint(msg.sender);
    }

    // public sale mint
    function mint(uint256 count) public payable {
        if (count == 0) {
            revert PandaNft__CountZero();
        }

        if (state != State.PublicSale) {
            revert PandaNft__NotPublicSaleState();
        }

        if (totalSupply() + count > maxSupply) {
            revert PandaNft__MaxSupplyReached();
        }

        if (balanceOf(msg.sender) + count > maxPerAccount) {
            revert PandaNft__MaxPerAccountReached();
        }

        // calculate free count
        uint256 freeCount = leftFreeCount();
        if (freeCount > count) {
            freeCount = count;
        }

        // value enough?
        uint256 needWei = (count - freeCount) * price;
        if (msg.value < needWei) {
            revert PandaNft__EthNotEnough();
        }

        // refund
        if (msg.value > needWei) {
            payable(msg.sender).transfer(msg.value - needWei);
        }

        // mint
        for (uint256 i = 0; i < count; i++) {
            ++tokenCounter;
            _safeMint(msg.sender, tokenCounter);
        }

        emit Mint(msg.sender);
    }

    function leftFreeCount() internal view returns (uint256) {
        if (totalSupply() < maxFreeCount) {
            return maxFreeCount - totalSupply();
        }
        return 0;
    }

    // withraw all balance of the contract
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) {
            return;
        }

        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender);
    }

    // receive
    receive() external payable {}
}
