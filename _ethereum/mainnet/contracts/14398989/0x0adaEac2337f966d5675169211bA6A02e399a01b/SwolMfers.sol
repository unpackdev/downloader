// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
█████████████████ ▄▄█ ███ █▀▄▄▀█ ████ ▄▀▄ █ ▄▄█ ▄▄█ ▄▄▀█ ▄▄██████████████
█████████████████▄▄▀█▄▀ ▀▄█ ██ █ ████ █▄█ █ ▄██ ▄▄█ ▀▀▄█▄▄▀██████████████
█████████████████▄▄▄██▄█▄███▄▄██▄▄███▄███▄█▄███▄▄▄█▄█▄▄█▄▄▄██████████████
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀            
by @swolidity

artwork by @hal3zthatbitch & @quincypop1

special thanks to @donkey_brained

For Landon & Zane.                                      
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SwolMfers is ERC721A, Ownable, Pausable {
    uint256 public mintPrice = .0069 ether;
    uint256 public maxSwolMfers = 6969;
    uint256 public maxMint = 20;
    string public baseURI;

    address public euniDaoAddress = 0x083FEd9c3A2AB4d2541c95652d2068A8a471716f; // EuniDao contract
    address public sabcAddress = 0xaDC28cac9c1d53cC7457b11CC9423903dc09DDDc; // Sketchy Ape Book Club contract
    address public mferAddress = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f; // Mfer contract

    constructor() ERC721A("swol mfers", "SMFER") {
        setBaseURI("");
        _pause();
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 amount) external payable whenNotPaused {
        /**
         * @notice If you hold EuniDao, Sketchy Ape Book Club, or Mfers, you are eligible for up to 20 FREE mints.
         * MINT THOSE FIRST as the freeMint function checks your Swol Mfer balance and will not
         * allow more than 20 NFTs in your wallet whether you minted them free or not.
         * No refunds will be given for messing this up.
         */
        require(
            msg.value >= mintPrice * amount,
            "Not enough ETH for purchase mfer."
        );
        require(amount <= maxMint, "Save some for the rest of us mfer.");
        require(
            totalSupply() + amount <= maxSwolMfers,
            "Not enough swol mfers remaining."
        );
        _safeMint(msg.sender, amount);
    }

    function freeMint(uint256 amount) external payable whenNotPaused {
        /**
         * @notice If you hold EuniDao,  Sketchy Ape Book Club, or Mfers, you are eligible for up to 20 FREE mints.
         * MINT THESE FIRST as the freeMint function checks your Swol Mfer balance and will not
         * allow more than 20 NFTs in your wallet whether you minted them free or not.
         * No refunds will be given for messing this up.
         * @param amount The total of your EuniDao,  Sketchy Ape Book Club, and Mfer counts up to 20. Use checkTokenCounts
         * to confirm before minting.
         */

        // check EuniDao balance
        ERC721A euniToken = ERC721A(euniDaoAddress);
        uint256 euniOwnedAmount = euniToken.balanceOf(msg.sender);
        // check SABC balance
        ERC721A sabcToken = ERC721A(sabcAddress);
        uint256 sabcOwnedAmount = sabcToken.balanceOf(msg.sender);
        // check Mfer balance
        ERC721A mferToken = ERC721A(mferAddress);
        uint256 mferOwnedAmount = mferToken.balanceOf(msg.sender);
        // check Swol Mfer balance
        uint256 swolOwnedAmount = balanceOf(msg.sender);
        require(
            euniOwnedAmount + sabcOwnedAmount + mferOwnedAmount >= 1,
            "You don't own EuniDao, Sketchy Apes, or Mfers."
        );
        require(
            amount + swolOwnedAmount <=
                euniOwnedAmount + sabcOwnedAmount + mferOwnedAmount,
            "Not enough EuniDao, Sketchy Apes, and Mfers in wallet."
        );
        require(swolOwnedAmount + amount <= maxMint, "Max 20 Free.");
        require(
            totalSupply() + amount <= maxSwolMfers,
            "Not enough swol mfers remaining."
        );
        _safeMint(msg.sender, amount);
    }

    function devMint(address to, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= maxSwolMfers,
            "Not enough swol mfers remaining."
        );
        _safeMint(to, amount);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function lowerMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(
            _newMaxSupply < maxSwolMfers,
            "New supply must be less than current."
        );
        maxSwolMfers = _newMaxSupply;
    }

    function withdraw() public onlyOwner {
        uint256 total = address(this).balance;

        Address.sendValue(
            payable(0x294cB3785d0A3E7A6F1Cea6ebc449293D790c33F),
            (total * 3333) / 10000
        );
        Address.sendValue(
            payable(0x77f95EEB1CE65F44178e1faBC8726A010dB0Ef9E),
            (total * 3333) / 10000
        );

        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function checkTokenCounts(address owner)
        public
        view
        returns (
            uint256 euniDaoCount,
            uint256 mfersCount,
            uint256 swolMfersCount,
            uint256 sabcCount
        )
    {
        /**
         * @notice Enter your wallet address to see how many free mints you can claim (up to 20).
         * FREE MINT FIRST as the freeMint function checks your Swol Mfer balance and will not
         * allow more than 20 Swol Mfers NFTs in your wallet whether you minted them free or not.
         * No refunds will be given for messing this up.
         */

        ERC721A euniToken = ERC721A(euniDaoAddress);
        uint256 euniOwnedAmount = euniToken.balanceOf(owner);
        ERC721A mferToken = ERC721A(mferAddress);
        uint256 mferOwnedAmount = mferToken.balanceOf(owner);
        uint256 swolOwnedAmount = balanceOf(owner);
        ERC721A sabcToken = ERC721A(sabcAddress);
        uint256 sabcOwnedAmount = sabcToken.balanceOf(owner);
        return (
            euniOwnedAmount,
            mferOwnedAmount,
            swolOwnedAmount,
            sabcOwnedAmount
        );
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}
