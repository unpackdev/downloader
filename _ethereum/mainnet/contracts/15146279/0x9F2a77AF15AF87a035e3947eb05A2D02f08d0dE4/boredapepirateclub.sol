// SPDX-License-Identifier: MIT

/*
                                                           

  ____                     _                         _____ _           _          _____ _       _     
 |  _ \                   | |     /\                |  __ (_)         | |        / ____| |     | |    
 | |_) | ___  _ __ ___  __| |    /  \   _ __   ___  | |__) | _ __ __ _| |_ ___  | |    | |_   _| |__  
 |  _ < / _ \| '__/ _ \/ _` |   / /\ \ | '_ \ / _ \ |  ___/ | '__/ _` | __/ _ \ | |    | | | | | '_ \ 
 | |_) | (_) | | |  __/ (_| |  / ____ \| |_) |  __/ | |   | | | | (_| | ||  __/ | |____| | |_| | |_) |
 |____/ \___/|_|  \___|\__,_| /_/    \_\ .__/ \___| |_|   |_|_|  \__,_|\__\___|  \_____|_|\__,_|_.__/ 
                                       | |                                                            
                                       |_|                                                            


Website: https://boredapepirateclub.com
Twitter: https://twitter.com/BoredApePirateC
Instagram: https://www.instagram.com/BoredApePirateClub

*/

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

struct Voucher {
    uint256 allowance;
    uint256 id;
    address wallet;
    bytes signature;
}

enum MintMode {
    Closed,
    VoucherOnly,
    Open
}

contract BoredApePirateClub is ERC721Enumerable, EIP712, Ownable {
    uint256 public maxTokens = 10000;
    uint256 public cap = 10000;
    uint256 public tokenPrice = 50000000000000000;
    string _baseTokenURI;

    MintMode public mintMode = MintMode.Closed;
    address public voucherSigner;

    uint256 public devTokensMinted = 0;
    mapping(uint256 => uint256) public voucherBalance;

    address[] public teamWallets = [
        0x01aF6890EFBF82Eba5dE86FD5F266D08044E6822, // BugBunny
        0xaD9266E8F8d43A0686F938966572067F5CA8Ba26, // JacksonBunny
        0x1264BE719622B655Dd361AD366b09e60dE4D3a8F // BusinessBunny

    ];

    uint256[] public teamShares = [
        25, // BugBunny
        25, // JacksonBunny
        25 // BusinessBunny
    ]; // Rest goes to owner

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC721(tokenName, tokenSymbol) EIP712(tokenName, "1") {
        _baseTokenURI = baseURI;
    }

    // Mint Tokens
    function mint(uint256 n) public payable {
        require(mintMode == MintMode.Open, "Public mint is closed");
        require(n <= 20, "Too many tokens");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(totalSupply() + n <= cap, "Can't fulfill requested tokens");

        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    // Mint tokens using voucher
    function mintWithVoucher(uint256 n, Voucher calldata voucher)
        public
        payable
    {
        require(mintMode != MintMode.Closed, "Minting is closed");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(totalSupply() + n <= cap, "Can't fulfill requested tokens");
        require(
            voucherBalance[voucher.id] + n <= voucher.allowance,
            "Voucher doesn't have enough allowance"
        );
        require(verifyVoucher(voucher) == voucherSigner, "Invalid voucher");
        require(voucher.wallet == msg.sender, "This is not your voucher");

        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }

        voucherBalance[voucher.id] += n;
    }

    // Mint 1 token to each address in an array (owner only);
    function airdrop(address[] memory addr) external onlyOwner {
        require(
            totalSupply() + addr.length <= maxTokens,
            "Can't fulfill requested tokens"
        );
        for (uint256 i = 0; i < addr.length; i++) {
            _safeMint(addr[i], totalSupply() + 1);
        }
        devTokensMinted += addr.length;
    }

    // Get the base URI (internal)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set the token price
    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    // Set the cap
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    // Set the base URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Get the base URI
    function getBaseURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    // get all tokens owned by an address
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // Distribute
    function distribute() public {
        // Distribute if called by the owner
        if (msg.sender == owner()) {
            _distribute();
            return;
        }

        // Distribute if called by one of the team members
        for (uint256 i = 0; i < teamWallets.length; i++) {
            if (teamWallets[i] == msg.sender) {
                _distribute();
                return;
            }
        }
    }

    // Handles the actual distribution
    function _distribute() private {
        // Distribute funds to team
        uint256 totalBalance = address(this).balance;
        for (uint256 i = 0; i < teamWallets.length; i++) {
            payable(teamWallets[i]).transfer(
                (totalBalance * teamShares[i]) / 100
            );
        }

        // Send leftovers to owner
        if (address(this).balance > 0) {
            payable(owner()).transfer(address(this).balance);
        }
    }

    // Withdraw all
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Withdraw portion
    function withdrawPortion(uint256 portion) external onlyOwner {
        payable(msg.sender).transfer(portion);
    }

    // Set mintmode
    function setMintMode(MintMode _mode) external onlyOwner {
        mintMode = _mode;
    }

    // Set voucher signer
    function setVoucherSigner(address _signer) external onlyOwner {
        voucherSigner = _signer;
    }

    // Start presale
    function startPresale(
        uint256 _price,
        address _signer,
        uint256 _cap
    ) external onlyOwner {
        tokenPrice = _price;
        voucherSigner = _signer;
        cap = _cap;
        mintMode = MintMode.VoucherOnly;
    }

    // End presale
    function endPresale() external onlyOwner {
        voucherSigner = address(0x0);
        mintMode = MintMode.Closed;
    }

    // Start public sale
    function startPublicSale(uint256 _price, uint256 _cap) external onlyOwner {
        tokenPrice = _price;
        cap = _cap;
        mintMode = MintMode.Open;
    }

    // Used for voucher verification
    function hashVoucher(Voucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 allowance,uint256 id,address wallet)"
                        ),
                        voucher.allowance,
                        voucher.id,
                        voucher.wallet
                    )
                )
            );
    }

    // Verify voucher and extract signer address
    function verifyVoucher(Voucher calldata voucher)
        public
        view
        returns (address)
    {
        bytes32 digest = hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}