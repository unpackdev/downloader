// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Constants.sol";

contract AZDAOToken is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct User {
        address invited_by;
        uint8 n_tokens;
        uint8 to_redeem;
    }

    mapping(address => bool) existingUsers;
    mapping(string => bool) existingURIs;
    mapping(address => User) users;
    bool _isPaused;
    bool _whitelistPaused;

    constructor() ERC721("AZDAOToken", "AZT") {}

    modifier notPaused {
        require(!_isPaused);
        _;
    }

    modifier onlyowner {
        require(msg.sender == Constants.OWNER);
        _;
    }

    function togglePause() public onlyowner{
        _isPaused = !_isPaused;
    }

    function toggleWhitelistPause() public onlyowner {
        require(msg.sender == Constants.OWNER);
        _whitelistPaused = !_whitelistPaused;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri];
    }

    function payToMint(address invited_by, string[] memory metadataURIs) public notPaused payable {
        address recipient = msg.sender;
        require(msg.value >= metadataURIs.length * Constants.PRICE, 'Not enough coins');
        require(metadataURIs.length <= Constants.MAX_TOKENS, 'Too many tokens');
        require(recipient != invited_by, "You cant invite yourself");

        uint8 n = uint8(metadataURIs.length);

        if (!existingUsers[recipient]) {
            User memory new_user = User(invited_by, 0, 0);
            users[recipient] = new_user;
            existingUsers[recipient] = true;
        }

        User memory user = users[recipient];

        if (user.n_tokens + user.to_redeem + n > Constants.MAX_TOKENS) {
            revert('You have reached the maximum number of tokens');
        }

        for (uint i = 0; i < metadataURIs.length; i++) {
            if (existingURIs[metadataURIs[i]]) {
                revert("Token already minted by someone else");
            }

            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            existingURIs[metadataURIs[i]] = true;

            _mint(recipient, newItemId);
            _setTokenURI(newItemId, metadataURIs[i]);
        }

        payable(Constants.OWNER).transfer(msg.value);

        user.n_tokens += n;

        if (!existingUsers[invited_by]) {
            User memory very_new_user = User(address(0), 0, 0);
            users[invited_by] = very_new_user;
            existingUsers[invited_by] = true;
        }

        User memory inviter = users[invited_by];

        if (inviter.n_tokens + inviter.to_redeem + n > Constants.MAX_TOKENS) {
            inviter.to_redeem = Constants.MAX_TOKENS - inviter.n_tokens;
        } else {
            inviter.to_redeem += n;
        }
        user.invited_by = invited_by;

        users[invited_by] = inviter;
        users[recipient] = user;
    }

    function redeem(string[] memory metadataURIs) public notPaused {
        address recipient = msg.sender;
        require(existingUsers[recipient], 'User does not exist');
        User memory user = users[recipient];
        require(user.to_redeem > 0, 'No tokens to redeem');

        uint8 n = user.to_redeem;
        for (uint i = 0; i < n; i++) {
            if (existingURIs[metadataURIs[i]]) {
                revert("Token already minted by someone else!");
            }

            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            existingURIs[metadataURIs[i]] = true;

            _mint(recipient, newItemId);
            _setTokenURI(newItemId, metadataURIs[i]);
        }

        user.to_redeem = 0;
        user.n_tokens += n;

        users[recipient] = user;
    }

    function redeemFromWhitelist(string memory metadataURI, string memory key) public notPaused {
        require(!_whitelistPaused, 'Whitelist is paused');
        require(keccak256(bytes(key)) == Constants.KEY, "Invalid key");
        require(!existingURIs[metadataURI], "Token already minted!");
        require(!existingUsers[msg.sender]);

        address recipient = msg.sender;
        users[recipient] = User(address(0), 1, 0);
        existingUsers[recipient] = true;

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        existingURIs[metadataURI] = true;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);
    }

    function getUser(address addr) public view returns (User memory) {
        return users[addr];
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}