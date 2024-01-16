
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ChainRunnersItems.sol";

contract ChainRunnersItemsBaseRenderer is Ownable, ChainRunnersItemRenderer {
    string _baseUri;

    function setBaseUri(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(
            _baseUri,
            Strings.toString(id),
            ".json"
        ));
    }
}
