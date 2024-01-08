//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract Epoch is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIDCounter;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 private constant _MINT_PRICE = (0.05 ether / 1 wei);
    uint256 private constant _MAX_NFTS = 6400;
    string private _baseURIStorage;
    address payable private _fundsReceiver;

    constructor() ERC721("EPOCH", "EPOCH") {
        _tokenIDCounter.increment();
    }

    function setRoyalties(
        uint256 _tokenID,
        address payable _royaltiesReceiverAddress,
        uint96 _percentageBasisPoints
    ) public onlyOwner {
        _setRoyalties(
            _tokenID,
            _royaltiesReceiverAddress,
            _percentageBasisPoints
        );
    }

    function _setRoyalties(
        uint256 _tokenID,
        address payable _royaltiesReceiverAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceiverAddress;
        _saveRoyalties(_tokenID, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];

        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice.mul(_royalties[0].value).div(10000))
            );
        }
        return (address(0), 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIStorage;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURIStorage = _newBaseURI;
    }

    function setFundsReceiver(address _newReceiver) public onlyOwner {
        _fundsReceiver = payable(_newReceiver);
    }

    function getFundsReceiver() public view returns (address) {
        return _fundsReceiver;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_baseURIStorage).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

    function claimNFT() public payable returns (uint256) {
        require(
            msg.value == _MINT_PRICE,
            "Send the correct redeem price - 0.05eth"
        );
        require(
            _tokenIDCounter.current() <= _MAX_NFTS,
            "Cannot claim any more NFTs"
        );

        _fundsReceiver.transfer(msg.value);

        _mint(_msgSender(), _tokenIDCounter.current());
        _setRoyalties(_tokenIDCounter.current(), _fundsReceiver, 500);
        _tokenIDCounter.increment();

        return (_tokenIDCounter._value - 1);
    }
}
