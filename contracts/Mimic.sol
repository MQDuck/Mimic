pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Mimic is ERC721("Mimic", "MIMIC"), IERC2981 {
    error NoAvailableTokens();
    error NotOwner();
    error CallFailed();

    uint256 private constant BITS_PER_TRAIT = 48;
    uint256 private constant DEFAULT_MINT_PRICE = 1e16; // 0.01 ether
    uint256 private constant MINT_PRICE_COEFFICIENT = $$(round(1.15 * (2**16 - 1)));
    uint256 private constant ROYALTY_PORTION = $$(round(1.1 * (2**16 - 1)));
    uint256 private constant MAX_TOKENS = 1000;

    uint48[][] TRAIT_TABLE = [
        [
            21243394468729,
            42486788937458,
            63730183406187,
            84973577874916,
            106216972343645,
            127460366812374,
            148703761281103,
            169947155749832,
            191190550218561,
            212433944687290,
            223055641921655,
            233677339156020,
            244299036390385,
            254920733624750,
            265542430859115,
            276164128093480,
            278819552402072
        ],
        [
            21243394468729,
            42486788937458,
            63730183406187,
            84973577874916,
            106216972343645,
            127460366812374,
            148703761281103,
            169947155749832,
            191190550218561,
            212433944687290,
            223055641921655,
            233677339156020,
            244299036390385,
            254920733624750,
            265542430859115,
            276164128093480,
            278819552402072
        ],
        [
            21243394468729,
            42486788937458,
            63730183406187,
            84973577874916,
            106216972343645,
            127460366812374,
            148703761281103,
            169947155749832,
            191190550218561,
            212433944687290,
            223055641921655,
            233677339156020,
            244299036390385,
            254920733624750,
            265542430859115,
            276164128093480,
            278819552402072
        ],
        [
            21243394468729,
            42486788937458,
            63730183406187,
            84973577874916,
            106216972343645,
            127460366812374,
            148703761281103,
            169947155749832,
            191190550218561,
            212433944687290,
            223055641921655,
            233677339156020,
            244299036390385,
            254920733624750,
            265542430859115,
            276164128093480,
            278819552402072
        ],
        [
            21243394468729,
            42486788937458,
            63730183406187,
            84973577874916,
            106216972343645,
            127460366812374,
            148703761281103,
            169947155749832,
            191190550218561,
            212433944687290,
            223055641921655,
            233677339156020,
            244299036390385,
            254920733624750,
            265542430859115,
            276164128093480,
            278819552402072
        ]
    ];

    uint256 private _numTokens = 0;

    //noinspection NoReturn
    function _generateTokenId() private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encode(block.timestamp, msg.sender)));

        while (true) {
            uint256 tokenId = 0;

            uint i = 0;
            while (true) {
                uint48[] storage traits = TRAIT_TABLE[i];
                uint256 roll = uint256(uint48(rand));
                uint t = 0;
                while (t < traits.length && roll > traits[t]) {
                    ++t;
                }
                tokenId |= t;

                if (++i == TRAIT_TABLE.length) {
                    break;
                }

                tokenId <<= BITS_PER_TRAIT;
                rand >>= BITS_PER_TRAIT;
            }
            delete i;

            if (!_exists(tokenId)) {
                return tokenId;
            }

            rand = uint256(keccak256(abi.encode(rand)));
        }
    }

    function _mintPrice(uint256 balance) private view returns (uint256) {
        return _numTokens == 0 ? DEFAULT_MINT_PRICE : MINT_PRICE_COEFFICIENT * balance / _numTokens / type(uint16).max;
    }

    function mintPrice() external view returns (uint256) {
        return _mintPrice(address(this).balance);
    }

    function _refundPrice(uint256 balance) private view returns (uint256) {
        return balance / _numTokens;
    }

    function refundPrice() external view returns (uint256) {
        return _refundPrice(address(this).balance);
    }

    function mint() external payable {
        uint256 price = _mintPrice(address(this).balance - msg.value);

        if (_numTokens == MAX_TOKENS) {
            revert NoAvailableTokens();
        }

        _safeMint(msg.sender, _generateTokenId());
        ++_numTokens;

        if (msg.value != price) {
            (bool success,) = msg.sender.call{value: msg.value - price}(""); // note: throws when msg.value is too low
            if (!success) {
                revert CallFailed();
            }
        }
    }

    function burn(uint256 tokenId) external {
        uint256 refund = _refundPrice(address(this).balance);

        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwner();
        }

        _burn(tokenId);
        --_numTokens;

        (bool success,) = msg.sender.call{value: refund}("");
        if (!success) {
            revert CallFailed();
        }
    }

    function burnAndMint(uint256 burnTokenId) external payable {
        uint256 priceDelta = address(this).balance - msg.value; // temporarily use variable for intermediate value
        priceDelta = _mintPrice(priceDelta) - _refundPrice(priceDelta);

        if (msg.sender != ownerOf(burnTokenId)) {
            revert NotOwner();
        }

        _safeMint(msg.sender, _generateTokenId());
        _burn(burnTokenId);

        if (msg.value != priceDelta) {
            (bool success,) = msg.sender.call{value: msg.value - priceDelta}(""); // note: throws when msg.value is too low
            if (!success) {
                revert CallFailed();
            }
        }
    }

    function royaltyInfo(
        uint256 /*tokenId*/,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (address(this), salePrice * ROYALTY_PORTION / type(uint16).max);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}
