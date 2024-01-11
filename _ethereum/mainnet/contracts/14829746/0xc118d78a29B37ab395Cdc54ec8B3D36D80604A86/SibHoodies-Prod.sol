// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//   .d8888b.  d8b 888      888 d8b                   888               888                \\
//  d88P  Y88b Y8P 888      888 Y8P                   888               888                \\
//  Y88b.          888      888                       888               888                \\
//   "Y888b.   888 88888b.  888 888 88888b.   .d88b.  888       8888b.  88888b.  .d8888b   \\
//      "Y88b. 888 888 "88b 888 888 888 "88b d88P"88b 888          "88b 888 "88b 88K       \\
//        "888 888 888  888 888 888 888  888 888  888 888      .d888888 888  888 "Y8888b.  \\
//  Y88b  d88P 888 888 d88P 888 888 888  888 Y88b 888 888      888  888 888 d88P      X88  \\
//   "Y8888P"  888 88888P"  888 888 888  888  "Y88888 88888888 "Y888888 88888P"   88888P'  \\
//                                                888                                      \\
//                                           Y8b d88P                                      \\
//                                            "Y88P"                                       \\

import "./ERC1155.sol";

import "./AdminPrivileges.sol";
import "./RoyaltiesConfig.sol";
import "./Allowlist.sol";
import "./AdminPause.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/// @author Sibling Labs
contract SibHoodies is ERC1155, AdminPrivileges, RoyaltiesConfig, Allowlist, AdminPause {
    address constant public ASH_ADDRESS = 0x64D91f12Ece7362F91A6f8E7940Cd55F05060b92;
    address private payoutAddress;

    uint256 public ASH_PRICE = 15 * 10 ** 18; // 15 ASH
    uint256 public ASH_PRICE_AL = 5 * 10 ** 18; // 5 ASH
    uint256 public ETH_PRICE = 0.03 ether;
    uint256 public ETH_PRICE_AL = 0.01 ether;
    uint256 public totalMints;
    uint8 constant public MAX_SUPPLY = 100;

    mapping(uint256 => string) private uris;
    mapping(address => uint8) public mintClaimed;

    bool public tokenRedeemable = true;
    bool public alRequired = true;
    bool public tokenLocked;
    bool public saleActive;

    constructor() ERC1155("") {
        payoutAddress = msg.sender;
    }

    // PUBLIC FUNCTIONS //

    /// @notice Mint a token
    /// @param ashPayment Determines whether payment will be made in ASH (ERC-20) or ETH
    function mint(bool ashPayment) public payable whenNotPaused {
        require(saleActive, "Mint is not available now");
        require(totalMints < MAX_SUPPLY, "All tokens have been minted");
        require(mintClaimed[msg.sender] == 0, "You have already minted");

        uint256 eth_price = ETH_PRICE;
        uint256 ash_price = ASH_PRICE;

        if (alRequired) {
            require(allowlist[msg.sender] > 0, "You must be on the allowlist to mint now");
            eth_price = ETH_PRICE_AL;
            ash_price = ASH_PRICE_AL;
        }

        if (ashPayment) {
            require(
                IERC20(ASH_ADDRESS).transferFrom(msg.sender, payoutAddress, ash_price),
                "Ash Payment failed - check if this contract is approved"
            );
        } else {
            require(msg.value == eth_price, "Incorrect amount of Ether sent");
        }

        mintClaimed[msg.sender]++;
        _mint(msg.sender, 1, 1, "");
    }

    /// @notice Redeem a token for a physical hoodie - use https://anniversary.clothing/
    /// @param amount The amount of tokens to redeem
    function redeem(uint256 amount) public whenNotPaused {
        require(tokenRedeemable, "Merch redemption is not available now");
        require(amount > 0, "Cannot redeem less than one");
        _burn(msg.sender, 1, amount);
        _mint(msg.sender, 2, amount, "");
    }

    /// @notice Indicates whether a given token is transferrable
    /// @param tokenId The token ID to check
    /// @return Boolean indicating whether the provided token ID is transferrable
    function isTokenLocked(uint8 tokenId) public view returns (bool) {
        return tokenId == 1 && !tokenLocked ? false : true;
    }

    // ADMIN FUNCTIONS //

    function airdrop(address[] calldata to, uint8 tokenId) public onlyAdmins {
        require(tokenId == 1 || tokenId == 2);
        for (uint256 i; i < to.length; i++) {
            _mint(to[i], tokenId, 1, "");
        }
    }

    function setPrices(uint256[4] calldata prices) public onlyAdmins {
        ASH_PRICE = prices[0];
        ASH_PRICE_AL = prices[1];
        ETH_PRICE = prices[2];
        ETH_PRICE_AL = prices[3];
    }

    function setPayoutAddress(address _addr) public onlyAdmins {
        payoutAddress = _addr;
    }

    function setSaleActive(bool active) public onlyAdmins {
        saleActive = active;
    }

    function setAlRequirement(bool required) public onlyAdmins {
        alRequired = required;
    }

    function setTokenRedeemable(bool redeemable) public onlyAdmins {
        tokenRedeemable = redeemable;
    }

    function setTokenLock(bool locked) public onlyAdmins {
        tokenLocked = locked;
    }

    function setURI(uint8 tokenId, string memory _uri) public onlyAdmins {
        uris[tokenId] = _uri;
    }

    function withdraw() public onlyAdmins {
        payable(owner).transfer(address(this).balance);
    }

    // METADATA & MISC FUNCTIONS //

    /// @notice Indicates which 'phase' the contract is considered to be in
    /// @return Phase of contract, as an integer
    function phase() public view returns (uint256) {
        if(tokenLocked) {
            return tokenRedeemable ? 2 : 3;
        } else {
            return tokenRedeemable ? 1 : 4;
        }
    }

    /// @notice See {IERC165-supportsInterface}
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(RoyaltiesConfig, ERC1155)
    returns (bool)
    {
        return RoyaltiesConfig.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return uris[tokenId];
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    internal
    override(ERC1155)
    whenNotPaused
    {
        if (from != address(0) && to != address(0)) {
            require(!tokenLocked, "This token may not be transferred now");
            for (uint256 i; i < ids.length; i++) {
                require(ids[i] == 1, "This token may not be transferred");
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        if (id == 1) {
            totalMints += amount;
        }
        super._mint(to, id, amount, data);
    }
}