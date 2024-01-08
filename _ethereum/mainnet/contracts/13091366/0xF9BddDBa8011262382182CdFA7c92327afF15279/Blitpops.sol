// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC165Storage.sol";
import "./Strings.sol";

import "./IBlitmap.sol";
import "./Base64.sol";
import "./StringUtils.sol";


contract Blitpops is ERC721Enumerable, Ownable, ERC165Storage {
    using strings for *;
    using Strings for uint256;

    struct FilterMatrix {
        uint256 revisions;
        string filter1;
        string filter2;
        string filter3;
    }

    mapping(uint256 => FilterMatrix) internal filterMap;
    uint256 public constant MINT_PRICE = 0.02 ether;
    uint256 public constant ROYALTY_AMOUNT = 10;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;
    address public BLITMAP_ADDRESS;
    uint256 public ownerSaleEnd;
    bool public editingAllowed;
    mapping(string => string) internal filters;
    string[] internal filterNames;

    constructor(address blitmapAddress) payable ERC721("Blitpop", "BLITPOP") {
        _registerInterface(_INTERFACE_ID_ERC2981);
        BLITMAP_ADDRESS = blitmapAddress;
        filters['og'] = '<svg>';
        filters['campbells'] = '<filter id="campbells"><feColorMatrix type="matrix" values="1 0 0 1.9 -2.2 0 1 0 0.0 0.3 0 0 1 0 0.5 0 0 0 1 0.2"></feColorMatrix></filter><svg filter="url(#campbells)">';
        filters['electric-chair'] = '<filter id="ec"><feColorMatrix type="matrix" values="1 0 0 0 0 -0.4 1.3 -0.4 0.2 -0.1 0 0 1 0 0 0 0 0 1 0"></feColorMatrix></filter><svg filter="url(#ec)">';
        filters['marilyn'] = '<filter id="marilyn"><feColorMatrix type="matrix" values="1 0 0 1.7 -1.6 0 1 0 0.0 0.3 -0.7 0 1 0 0.5 0 0 0 1 0.2"></feColorMatrix></filter><svg filter="url(#marilyn)">';
        filters['brillo'] = '<filter id="brillo"><feColorMatrix type="matrix" values="0 1.0 0 0 0 0 1.0 0 0 0 0 0.6 1 0 0 0 0 0 1 0 "/></filter><svg filter="url(#brillo)">';
        filters['b&w'] = '<filter id="bw"><feColorMatrix type="matrix" values="0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 1 0 "/></filter><svg filter="url(#bw)">';
        filterNames = ['og', 'campbells', 'electric-chair', 'marilyn', 'brillo', 'b&w'];
        ownerSaleEnd = block.timestamp + 7 days;
    }

    function addFilter(string memory name, string memory filter) public onlyOwner {
        filterNames.push(name);
        filters[name] = filter;
    }

    function setEditingAllowed(bool allowed) public onlyOwner {
        editingAllowed = allowed;
    }

    function listFilters() public view returns(string[] memory) {
        return filterNames;
    }

    function filtersFor(uint256 tokenId) public view returns (FilterMatrix memory) {
        return filterMap[tokenId];
    }

    function ownerMint(
        uint256 tokenId,
        string memory filter1,
        string memory filter2,
        string memory filter3) public payable {
        if (block.timestamp <= ownerSaleEnd){
            require(msg.value == MINT_PRICE, "Bp:oM:402");
            require(msg.sender == IBlitmap(BLITMAP_ADDRESS).ownerOf(tokenId), "Bp:oM:403");
        }

        if (block.timestamp > ownerSaleEnd) {
            require(msg.sender == owner(), "Bp:oM:403");
        }

        filterMap[tokenId] = FilterMatrix({
            revisions: 0,
            filter1: filter1,
            filter2: filter2,
            filter3: filter3
        });

        _safeMint(msg.sender, tokenId);
    }

    function updateFilters(
        uint256 tokenId,
        string memory filter1,
        string memory filter2,
        string memory filter3
    ) public {
        require(editingAllowed, "Bp:uF:400");
        require(msg.sender == ownerOf(tokenId), "Bp:uF:403");
        filterMap[tokenId] = FilterMatrix({
            revisions: filterMap[tokenId].revisions + 1,
            filter1: filter1,
            filter2: filter2,
            filter3: filter3
        });
    }

    /* solhint-disable quotes */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Bp:tU:404");

        FilterMatrix memory tokenFilters = filterMap[tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Blitpop ',
                                IBlitmap(BLITMAP_ADDRESS).tokenNameOf(tokenId),
                                '", "description":"Blitpops are onchain Blitmap derivatives. To construct the artwork, the original Blitmap with corresponding token ID is fetched, collaged and filtered to return a modified onchain SVG.", "image": "',
                                svgBase64Data(tokenId, tokenFilters.filter1, tokenFilters.filter2, tokenFilters.filter3),
                                '", ',
                                tokenProperties(tokenFilters),
                                '"}}'
                            )
                        )
                    )
                )
            );
    }

    function tokenProperties(FilterMatrix memory tokenFilters) internal view returns (bytes memory) {
        return abi.encodePacked(
            '"properties": { "revisions": "',
            tokenFilters.revisions.toString(),
            '", "Top Right": "',
            tokenFilters.filter1,
            '", "Bottom Left": "',
            tokenFilters.filter2,
            '", "Bottom Right": "',
            tokenFilters.filter3
        );
    }

    function svgBase64Data(
        uint256 tokenId,
        string memory filter1,
        string memory filter2,
        string memory filter3
    ) public view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(svgRaw(tokenId, filter1, filter2, filter3))
            )
        );
    }

    function svgRaw(
        uint256 tokenId,
        string memory filter1,
        string memory filter2,
        string memory filter3
    ) internal view returns (bytes memory) {
        string memory viewbox = 'viewBox="0 0 32 32">';
        strings.slice memory main = IBlitmap(BLITMAP_ADDRESS).tokenSvgDataOf(tokenId).toSlice();
        strings.slice memory start = main.split(viewbox.toSlice());

        return abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><svg viewBox="0 0 32 32" width="32" height="32">',
            main.toString(),
            '<svg viewBox="0 0 32 32" width="32" height="32" x="32">',
            filters[filter1],
            main.toString(),
            '</svg><svg viewBox="0 0 32 32" width="32" height="32" y="32">',
            filters[filter2],
            main.toString(),
            '</svg><svg viewBox="0 0 32 32" width="32" height="32" x="32" y="32">',
            filters[filter3],
            main.toString(),
            '</svg></svg>'
        );
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata _data
    ) external view returns (address _receiver, uint256 royaltyAmount) {
        royaltyAmount = (value * ROYALTY_AMOUNT) / 100;

        return (owner(), royaltyAmount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165Storage, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || ERC165Storage.supportsInterface(interfaceId);
    }
}
