// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

//   ,--,  ,---.  .-.   .-.,---.  _______  .---.  .-.  .-.  .--.     .---. .-. .-.,---.  ,---.    .---.
// .' .')  | .-.\  \ \_/ )/| .-.\|__   __|/ .-. ) | |/\| | / /\ \   ( .-._)| | | || .-'  | .-.\  ( .-._)
// |  |(_) | `-'/   \   (_)| |-' ) )| |   | | |(_)| /  \ |/ /__\ \ (_) \   | `-' || `-.  | `-'/ (_) \
// \  \    |   (     ) (   | |--' (_) |   | | | | |  /\  ||  __  | _  \ \  | .-. || .-'  |   (  _  \ \
//  \  `-. | |\ \    | |   | |      | |   \ `-' / |(/  \ || |  |)|( `-'  ) | | |)||  `--.| |\ \( `-'  )
//   \____\|_| \)\  /(_|   /(       `-'    )---'  (_)   \||_|  (_) `----'  /(  (_)/( __.'|_| \)\`----'
//             (__)(__)   (__)            (_)                             (__)   (__)        (__)

contract CryptoWashers is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    uint256 public constant COLLECTION_SIZE = 216;

    uint256 public constant PRICE_PER_1  = 0.25 ether;
    uint256 public constant PRICE_PER_2  = 0.50 ether;
    uint256 public constant PRICE_PER_3  = 0.75 ether;

    uint256 private _reserve = 6;

    bool    public  mintEnabled = false;

    string public CRYPTO_WASHER_PROVENANCE = "";
    string public baseURI = "https://crypto-washers.s3.us-west-1.amazonaws.com/meta/";

    address _safe = 0xB9797AB5c00C069559ADF8d1Abc9C969342D9a48;

    constructor() ERC721("CryptoWashers", "CRPTWSHRS") {}

    function setProvenance(string memory provenance) public onlyOwner {
        CRYPTO_WASHER_PROVENANCE = provenance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function getReserveLeft() public view returns (uint256) {
        return _reserve;
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function washersCollectionOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 count = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](count);
        for(uint256 i; i < count; i++){
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // = minting
    function mint(uint256 mintAmount) external payable {
        // mint must be enabled to continue
        require(mintEnabled, "Mint is not yet active.");

        // block mints from contracts
        require(msg.sender == tx.origin, "Reverted");

        // mint amount validation
        require(
            mintAmount == 1 ||
            mintAmount == 2 ||
            mintAmount == 3,
            "Can only mint one, two or three at once"
        );
        require(totalSupply().add(mintAmount) <= COLLECTION_SIZE - _reserve, "Not enough left");

        // mint cost validation
        require(
            (mintAmount == 1 && msg.value >= PRICE_PER_1) ||
            (mintAmount == 2 && msg.value >= PRICE_PER_2) ||
            (mintAmount == 3 && msg.value >= PRICE_PER_3),
            "Incorrect ether value sent"
        );

        for(uint i = 0; i < mintAmount; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < COLLECTION_SIZE - _reserve) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    // = reserve for a certain address
    function reserve(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount <= _reserve, "Not enough reserve left");

        uint current = totalSupply();
        for (uint i = 0; i < _amount; i++) {
            _safeMint(_to, current + i);
        }

        _reserve = _reserve - _amount;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawSafe() public onlyOwner {
        require(payable(_safe).send(address(this).balance));
    }
}