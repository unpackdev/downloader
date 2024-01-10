// SPDX-License-Identifier: UNLICENSED

/*

 ██████  ███    ███ ███████ ███████ ██████  ███████ 
██    ██ ████  ████ ██      ██      ██   ██ ██      
██    ██ ██ ████ ██ █████   █████   ██████  ███████ 
██    ██ ██  ██  ██ ██      ██      ██   ██      ██ 
 ██████  ██      ██ ██      ███████ ██   ██ ███████ 
                                                                                                                                                            

*/

pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./LayerZeroable.sol";


contract OmniMfersETH is ERC721Burnable, ERC721Enumerable, Ownable, LayerZeroable {
    uint16 public mintedSupply = 0;

    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public MAX_TXN = 15;
    uint256 public MAX_TXN_FREE = 2;

    uint256 public lastTokId = 0;
    uint256 public constant FREE_SUPPLY = 555;
    uint256 public constant PAID_SUPPLY = 2225;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY+PAID_SUPPLY;


    constructor(address _layerZeroEndpoint) ERC721("OmniMfers", "OMFERS") {
        saleEnabled = false;
        price = 0.0095 ether;
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        MAX_TXN = _maxTxn;
    }
    function setMaxTxnFree(uint256 _maxTxnFree) external onlyOwner {
        MAX_TXN_FREE = _maxTxnFree;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setLastTokenId(uint256 _last) external onlyOwner {
        lastTokId = _last;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(layerZeroEndpoint));
        require(
            _srcAddress.length == remotes[_srcChainId].length &&
                keccak256(_srcAddress) == keccak256(remotes[_srcChainId]),
            "Invalid remote sender address. owner should call setRemote() to enable remote contract"
        );

        // Decode payload
        (address to, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        _safeMint(to, tokenId);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require(mintedSupply+num <= MAX_SUPPLY, "Exceed max supply");

        for(uint i = 0; i < num; i++) {
            mintedSupply++;
            _safeMint(msg.sender, ++lastTokId);
        }
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(mintedSupply + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 15");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        for(uint i = 0; i < numOfTokens; i++) {
            mintedSupply++;
            _safeMint(msg.sender, ++lastTokId);
        }
    }

    function freeMint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(mintedSupply + numOfTokens <= (FREE_SUPPLY+lastTokId), "Exceed max supply");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 2");
        require(numOfTokens > 0, "Must mint at least 1 token");

        for(uint i = 0; i < numOfTokens; i++) {
            mintedSupply++;
            _safeMint(msg.sender, ++lastTokId);
        }
    }

    function donate() external payable {
        // feel free to donate :)
    }

    function transferToChain(
        uint256 _tokenId,
        address _to,
        uint16 _chainId
    ) external payable {
        require(ownerOf(_tokenId) == _msgSender(), "Sender is not owner");
        require(remotes[_chainId].length > 0, "Remote not configured");

        _burn(_tokenId);

        bytes memory payload = abi.encode(_to, _tokenId);

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, destGasAmount);

        (uint256 messageFee, ) = layerZeroEndpoint.estimateFees(
            _chainId,
            _bytesToAddress(remotes[_chainId]),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= messageFee,
            "Insufficient amount to cover gas costs"
        );

        layerZeroEndpoint.send{value: msg.value}(
            _chainId,
            remotes[_chainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function estimateFee(
        uint256 _tokenId,
        address _to,
        uint16 _chainId
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        bytes memory payload = abi.encode(_to, _tokenId);

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, destGasAmount);

        return
            layerZeroEndpoint.estimateFees(
                _chainId,
                _bytesToAddress(remotes[_chainId]),
                payload,
                false,
                adapterParams
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}