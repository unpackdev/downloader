// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**
 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract JurasickPets is ERC721A, Ownable, ReentrancyGuard {
    bool publicSale = false;
    bool wlSale = false;
    address wlSigner;
    address payable jpWallet;
    address payable jpCommunityWallet;

    uint256 constant nbFree = 300;
    uint256 constant wlPrice = 0.06 ether;
    uint256 constant price = 0.08 ether;

    uint64 nbFreeMinted = 0;
    uint256 maxWLMint = 1;
    uint256 constant maxMint = 20;

    uint8 vestingStep = 0;

    uint64 constant limitAge2 = 259200; // Prod : 3j = 3 * 24 * 3600 = 259_200
    uint64 constant limitAge3 = 2851200; // Prod : 3 j+ 30j = 259_200 + 30 * 24 * 3600 = 259_200 + 2_592_000 = 2_851_200
    uint64 constant limitAge4 = 8035200; // Prod 3 j+ 30j + 60j = 259_200 + 2_592_000 + 2 * 2_592_000 = 8_035_200
    uint64 constant limitAge5 = 15811200; // Prod 3 j+ 30j + 60j + 90j = 259_200 + 2_592_000 + 2 * 2_592_000 + 3 * 2_592_000 = 15_811_200

    mapping(uint256 => uint256) private birthDate;
    mapping(uint256 => uint256) private familySize;

    mapping(uint8 => uint256) private vestingStepAllowedRatio;

    constructor(address _wlSigner, address payable _jpWallet, address payable _jpCommunityWallet) ERC721A("JurasickPets", "DINO", 20, 10000) {

        wlSigner = _wlSigner;
        jpWallet = _jpWallet;
        jpCommunityWallet = _jpCommunityWallet;
        vestingStepAllowedRatio[0] = 30; // +20 community only 1st step
        vestingStepAllowedRatio[1] = 20;
        vestingStepAllowedRatio[2] = 25;
        vestingStepAllowedRatio[3] = 32;
        vestingStepAllowedRatio[4] = 50;
        vestingStepAllowedRatio[5] = 100;
    }

    // Accessors :

    function getBirthDate(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "getBirthDate query for nonexistent token");
        return birthDate[tokenId];
    }

    function getAge(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "getAge query for nonexistent token");
        return block.timestamp - birthDate[tokenId];
    }

    function getEvolutionaryStage(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint256 age = getAge(tokenId);
        if (age < limitAge2) {
            return "Egg";
        }
        if (age < limitAge3) {
            return "Youngster";
        }
        if (age < limitAge4) {
            return "Grown-up";
        }
        if (age < limitAge5) {
            return "Oldie";
        }
        return "Fossil";
    }

    function getFamilySize(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "getFamilySize query for nonexistent token");
        return familySize[tokenId];
    }

    function updateBirthDate(uint256 tokenId) internal {
        if (tokenId >= totalSupply()) {
            birthDate[tokenId] = block.timestamp;
            return;
        }
        uint256 age = getAge(tokenId);
        if (age < limitAge2) {
            birthDate[tokenId] = block.timestamp; // Back to the beginning of Egg stage
        } else if (age < limitAge3) {
            birthDate[tokenId] = block.timestamp - limitAge2; // Back to the beginning of Youngster stage
        } else if (age < limitAge4) {
            birthDate[tokenId] = block.timestamp - limitAge3; // Back to the beginning of Grown-Up stage
        } else if (age < limitAge5) {
            birthDate[tokenId] = block.timestamp - limitAge4; // Back to the beginning of Oldie stage
        } else {
            birthDate[tokenId] = block.timestamp - limitAge5; // Back to the beginning of Fossil stage
        }
    }

    // MINTING

    function freeMint(uint64 quantity) external onlyOwner {
        require(nbFreeMinted + quantity <= nbFree, "Reached max free supply");
        nbFreeMinted = nbFreeMinted + quantity;
        _lfMint(quantity);
    }

    function wlMint(
        uint64 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable callerIsUser {
        require(wlSale, "Sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= maxWLMint, "Cannot mint this many at a time");
        require(
            wlPrice * quantity == msg.value,
            "Ether value sent is not correct"
        );
        require(super.balanceOf(msg.sender) + quantity <= maxWLMint, "Cannot mint more Dinos");
        bool checked = checkWL(msg.sender, v, r, s);
        require(checked, "You are not on the WL ... or not signed properly.");
        _lfMint(quantity);
    }

    function mint(uint64 quantity) external payable callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= maxMint, "Cannot mint this many at a time");
        require(
            price * quantity == msg.value,
            "Ether value sent is not correct"
        );
        _lfMint(quantity);
    }

    function _lfMint(uint256 quantity) private {
        for (uint256 i = totalSupply(); i < totalSupply() + quantity; i++) {
            updateBirthDate(i);

            // Family size :
            familySize[i] = super.balanceOf(msg.sender);
        }
        _safeMint(msg.sender, quantity);
    }

    function checkWL(
        address addr,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(addr))
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        return recovered == wlSigner;
    }

    // Update params :
    function setMaxWLMint(uint256 n) external onlyOwner nonReentrant {
        maxWLMint = n;
    }

    // Withdraw money

    function withdrawMoney() external onlyOwner nonReentrant {
        require(
            wlSale == false && publicSale == false,
            "Cannot get money if not minted out :("
        );
        require(checkVestingStep(), "Not authorized to take money now ;)");
        uint256 balanceToWithdraw = (address(this).balance / 100) * vestingStepAllowedRatio[vestingStep];
        if(vestingStep == 0) {
            // Send money to community wallet :
            uint256 balanceToWithdrawCommunity = (address(this).balance / 100) * 20;
            payable(jpCommunityWallet).transfer(balanceToWithdrawCommunity);
        }
        payable(jpWallet).transfer(balanceToWithdraw);
        vestingStep++;
    }

    function checkVestingStep() internal view returns (bool) {
        // After the mint ... first step
        if (vestingStep == 0) return true;
        if (vestingStep == 1 && block.timestamp > 1654034400) return true; // 2022-06-01
        if (vestingStep == 2 && block.timestamp > 1656626400) return true; // 2022-07-01
        if (vestingStep == 3 && block.timestamp > 1659304800) return true; // 2022-08-01
        if (vestingStep == 4 && block.timestamp > 1661983200) return true; // 2022-09-01
        if (vestingStep == 5 && block.timestamp > 1664575200) return true; // 2022-10-01
        return false;
    }

    function emergencyWithdrawMoney() external onlyOwner nonReentrant {
        require(
            block.timestamp >= 1664575200,
            "Cannot withdraw all before this date..."
        ); // 2022-10-01 0hZ
        
        payable(jpWallet).transfer(address(this).balance);
    }

    string private _baseTokenURI =
        "https://www.jurasickpets.com/jurasickpets-back/token/metadata/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Utils :

    function openWL() external onlyOwner {
        wlSale = true;
        publicSale = false;
    }

    function openPublic() external onlyOwner {
        wlSale = false;
        publicSale = true;
    }

    function closeSales() external onlyOwner {
        wlSale = false;
        publicSale = false;
    }

    function getSale() external view returns (string memory) {
        if (wlSale) return "wl";
        if (publicSale) return "public";
        return "none";
    }

    function updateFamilySize(address newOwner, uint256 tokenId) internal {
        familySize[tokenId] = super.balanceOf(newOwner);
    }

    /// ERC721 related
    /**
     * @dev See {ERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        updateFamilySize(to, tokenId);
        updateBirthDate(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        updateFamilySize(to, tokenId);
        updateBirthDate(tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        updateFamilySize(to, tokenId);
        updateBirthDate(tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    // Utils:

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}
