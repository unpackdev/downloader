// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Strings.sol";

// SPDX-License-Identifier: MIT

// This is the main building block for smart contracts.
contract Luckies is ERC1155, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    // Token name
    string public name = "Luckies";

    string public tokenURI;

    string public provenanceHash =
        "8a134a916d5846b08a629b813a694059857a8265ae0475b64dad1a314ca46592";

    uint256 public totalSupply;
    uint256 public constant MAX_TOKENS = 8888;
    uint256[MAX_TOKENS] internal indices;
    uint256 internal nonce = 0;

    // zodiac whitelists
    mapping(address => uint8) private whitelist_0Z;
    mapping(address => uint8) private whitelist_1Z;
    mapping(address => uint8) private whitelist_2Z;
    mapping(address => uint8) private whitelist_3Z;
    mapping(address => uint8) private whitelist_4Z;
    mapping(address => uint8) private whitelist_5Z;

    // zodiac whitelist activation timestamp
    uint256 private wl_timestamp_5Z;

    // token price tiers
    uint256 public tokenPrice;
    uint256 public tokenPrice2Z;
    uint256 public tokenPrice3Z;
    uint256 public tokenPrice4Z;
    uint256 public tokenPrice5Z;

    // event to emit when minting
    event MintEvent(uint256 timestamp, uint256 tokenId);

    constructor() ERC1155("") {
        totalSupply = 0;
        tokenPrice = 88000000000000000;
        tokenPrice2Z = 80000000000000000;
        tokenPrice3Z = 70000000000000000;
        tokenPrice4Z = 60000000000000000;
        tokenPrice5Z = 50000000000000000;
        tokenURI = "ipfs://QmecSGZ3wrZYGxGKejsW3xHEYiy12e5DMtqYTn5Dv9CH95/";
        setLaunchTime(1647356400);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // add to zodiac whitelists
    function addToSingleZodiacWL(
        address[] calldata accounts1Z1M,
        address[] calldata accounts1Z2M
    ) public onlyOwner {
        setWhitelist(accounts1Z1M, 1, 1);
        setWhitelist(accounts1Z2M, 1, 2);
    }

    // add to zodiac whitelists
    function addToMultipleZodiacWL(
        address[] calldata accounts2Z,
        address[] calldata accounts3Z,
        address[] calldata accounts4Z,
        address[] calldata accounts5Z
    ) public onlyOwner {
        setWhitelist(accounts2Z, 2, 2);
        setWhitelist(accounts3Z, 3, 3);
        setWhitelist(accounts4Z, 4, 4);
        setWhitelist(accounts5Z, 5, 5);
    }

    // remove from zodiac whitelists
    function removeFromZodiacWL(
        address[] calldata accounts1Z,
        address[] calldata accounts2Z,
        address[] calldata accounts3Z,
        address[] calldata accounts4Z,
        address[] calldata accounts5Z
    ) public onlyOwner {
        setWhitelist(accounts1Z, 1, 0);
        setWhitelist(accounts2Z, 2, 0);
        setWhitelist(accounts3Z, 3, 0);
        setWhitelist(accounts4Z, 4, 0);
        setWhitelist(accounts5Z, 5, 0);
    }

    // add to final whitelist
    function addToFinalWL(address[] calldata accounts) public onlyOwner {
        setWhitelist(accounts, 0, 8);
    }

    // remove from final whitelist
    function removeFromFinalWL(address[] calldata accounts) public onlyOwner {
        setWhitelist(accounts, 0, 0);
    }

    // internal whitelist functions
    function setWhitelist(
        address[] calldata accounts,
        uint8 zodiacs,
        uint8 value
    ) private onlyOwner {
        mapping(address => uint8) storage whitelist = whitelist_0Z;
        if (zodiacs == 1) {
            whitelist = whitelist_1Z;
        } else if (zodiacs == 2) {
            whitelist = whitelist_2Z;
        } else if (zodiacs == 3) {
            whitelist = whitelist_3Z;
        } else if (zodiacs == 4) {
            whitelist = whitelist_4Z;
        } else if (zodiacs == 5) {
            whitelist = whitelist_5Z;
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = value;
        }
    }

    // globabl URI setter
    function setGlobalURI(string memory newTokenURI) public onlyOwner {
        tokenURI = newTokenURI;
    }

    // URI function complying with OpenSea standard
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(tokenURI, Strings.toString(_tokenId), ".json")
            );
    }

    // set whitelist activation time
    function setLaunchTime(uint256 launchTimestamp) public onlyOwner {
        wl_timestamp_5Z = launchTimestamp;
    }

    // how many am I allowed to mint and at what price?
    function getAllowance(address account)
        public
        view
        returns (
            uint8 quantity,
            uint256 price,
            uint256 wait_time
        )
    {
        if (whitelist_5Z[account] > 0) {
            return (
                whitelist_5Z[account],
                tokenPrice5Z,
                block.timestamp < wl_timestamp_5Z
                    ? wl_timestamp_5Z - block.timestamp
                    : 0
            );
        } else if (whitelist_4Z[account] > 0) {
            uint256 wl_timestamp_4Z = wl_timestamp_5Z + 2 hours;
            return (
                whitelist_4Z[account],
                tokenPrice4Z,
                block.timestamp < wl_timestamp_4Z
                    ? wl_timestamp_4Z - block.timestamp
                    : 0
            );
        } else if (whitelist_3Z[account] > 0) {
            uint256 wl_timestamp_3Z = wl_timestamp_5Z + 4 hours;
            return (
                whitelist_3Z[account],
                tokenPrice3Z,
                block.timestamp < wl_timestamp_3Z
                    ? wl_timestamp_3Z - block.timestamp
                    : 0
            );
        } else if (whitelist_2Z[account] > 0) {
            uint256 wl_timestamp_2Z = wl_timestamp_5Z + 4 hours;
            return (
                whitelist_2Z[account],
                tokenPrice2Z,
                block.timestamp < wl_timestamp_2Z
                    ? wl_timestamp_2Z - block.timestamp
                    : 0
            );
        } else if (whitelist_1Z[account] > 0) {
            uint256 wl_timestamp_1Z = wl_timestamp_5Z + 4 hours;
            return (
                whitelist_1Z[account],
                tokenPrice,
                block.timestamp < wl_timestamp_1Z
                    ? wl_timestamp_1Z - block.timestamp
                    : 0
            );
        } else if (whitelist_0Z[account] > 0) {
            uint256 wl_timestamp_0Z = wl_timestamp_5Z + 1 days;
            return (
                whitelist_0Z[account],
                tokenPrice,
                block.timestamp < wl_timestamp_0Z
                    ? wl_timestamp_0Z - block.timestamp
                    : 0
            );
        } else if (block.timestamp > wl_timestamp_5Z + 2 days) {
            return (8, tokenPrice, 0);
        } else return (0, tokenPrice, 1);
    }

    // public mint function
    function mint(uint256 amount) public payable nonReentrant whenNotPaused {
        (uint8 quantity, uint256 price, uint256 wait_time) = getAllowance(
            msg.sender
        );

        // quantity checks
        require(amount > 0, "zero_tokens");
        require(quantity > 0, "no_mints");
        require(amount <= quantity, "over_allowed_mints");
        require(amount <= 8, "over_max_mint");
        require(totalSupply.add(amount) <= MAX_TOKENS, "over_max_supply");

        // whitelist activation check
        require(wait_time == 0, "whitelist_inactive");

        // price check
        require(msg.value >= price.mul(amount), "low_funds");

        for (uint256 i = 0; i < amount; i++) {
            _mintWithRandomTokenId(msg.sender);
        }

        deductAllowance(msg.sender, amount);
    }

    function deductAllowance(address account, uint256 amount) internal {
        if (whitelist_5Z[account] > 0) {
            whitelist_5Z[account] = uint8(whitelist_5Z[account].sub(amount));
        } else if (whitelist_4Z[account] > 0) {
            whitelist_4Z[account] = uint8(whitelist_4Z[account].sub(amount));
        } else if (whitelist_3Z[account] > 0) {
            whitelist_3Z[account] = uint8(whitelist_3Z[account].sub(amount));
        } else if (whitelist_2Z[account] > 0) {
            whitelist_2Z[account] = uint8(whitelist_2Z[account].sub(amount));
        } else if (whitelist_1Z[account] > 0) {
            whitelist_1Z[account] = uint8(whitelist_1Z[account].sub(amount));
        } else if (whitelist_0Z[account] > 0) {
            whitelist_0Z[account] = uint8(whitelist_0Z[account].sub(amount));
        }
    }

    // Required override from parent contract
    function burn(uint256 id) public nonReentrant {
        super._burn(msg.sender, id, 1);
    }

    // Allow admin minting of tokens to a given account
    function adminMint(address account, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        require(totalSupply.add(amount) < MAX_TOKENS, "over_max_supply");
        for (uint256 i = 0; i < amount; i++) {
            _mintWithRandomTokenId(account);
        }
    }

    // Mint a token with random id
    function _mintWithRandomTokenId(address _to) private {
        uint256 _tokenID = Random.randomIndex(
            MAX_TOKENS,
            totalSupply,
            nonce,
            msg.sender,
            indices
        );
        _mint(_to, _tokenID, 1, "");
        totalSupply += 1;

        emit MintEvent(block.timestamp, _tokenID);
    }

    // When the contract is paused, all token transfers are prevented in case of emergency
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

library Random {
    using SafeMath for uint256;

    // Pick a random index
    function randomIndex(
        uint256 max_tokens,
        uint256 totalSupply,
        uint256 nonce,
        address account,
        uint256[8888] storage indices
    ) public returns (uint256) {
        uint256 totalSize = max_tokens - totalSupply;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    account,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;

        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;
        } else {
            indices[index] = indices[totalSize - 1];
        }
        uint256 val = value.add(1);
        return val;
    }
}
