// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketPlace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable holder;
    uint256 listingPrice = 0.0025 ether;
    uint256 mintingPrice = 0.0075 ether;

    constructor() {
        holder = payable(msg.sender);
    }

    struct Item {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable holder;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => Item) private idToItem;

    event ItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address holder,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price cannot be zero");
        require(msg.value == listingPrice, "Price cannot be listing fee");
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        idToItem[itemId] = Item(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit ItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    function n2DMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint price = idToItem[itemId].price;
        uint tokenId = idToItem[itemId].tokenId;
        require(
            msg.value == price,
            "Not enough balance"
        );
        idToItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToItem[itemId].holder = payable(msg.sender);
        idToItem[itemId].sold = true;
        _itemsSold.increment();
        payable(holder).transfer(listingPrice);
    }

    function getAvailableNft() public view returns (Item[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        Item[] memory items = new Item[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToItem[i + 1].holder == address(0)) {
                uint currentId = i + 1;
                Item storage currentItem = idToItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getMyNft() public view returns (Item[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].holder == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].holder == msg.sender) {
                uint currentId = i + 1;
                Item storage currentItem = idToItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getMyMarketNfts() public view returns (Item[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                Item storage currentItem = idToItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
