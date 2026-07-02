from enum import Enum


class ProductCategory(str, Enum):
    MIE_INSTAN = "mie_instan"
    KERIPIK_SNACK = "keripik_snack"
    MAKANAN_KALENG = "makanan_kaleng"
    BISKUIT_ROTI = "biskuit_roti"
    FROZEN_FOOD = "frozen_food"
    SEREAL = "sereal"
    BISKUIT = "biskuit"
    SUSU = "susu"
    MINUMAN_KEMASAN = "minuman_kemasan"
    SAUS_BUMBU = "saus_bumbu"
    LAINNYA = "lainnya"


VALID_PRODUCT_CATEGORY_VALUES = tuple(category.value for category in ProductCategory)

CATEGORY_FALLBACK_MAP: dict[ProductCategory, list[ProductCategory]] = {
    ProductCategory.KERIPIK_SNACK: [
        ProductCategory.BISKUIT,
        ProductCategory.BISKUIT_ROTI,
        ProductCategory.SEREAL,
    ],
    ProductCategory.MIE_INSTAN: [
        ProductCategory.MAKANAN_KALENG,
        ProductCategory.FROZEN_FOOD,
    ],
    ProductCategory.BISKUIT: [
        ProductCategory.KERIPIK_SNACK,
        ProductCategory.SEREAL,
    ],
    ProductCategory.BISKUIT_ROTI: [
        ProductCategory.KERIPIK_SNACK,
        ProductCategory.SEREAL,
    ],
    ProductCategory.SUSU: [
        ProductCategory.MINUMAN_KEMASAN,
    ],
    ProductCategory.MINUMAN_KEMASAN: [
        ProductCategory.SUSU,
    ],
    ProductCategory.SAUS_BUMBU: [
        ProductCategory.MAKANAN_KALENG,
    ],
    ProductCategory.FROZEN_FOOD: [
        ProductCategory.MAKANAN_KALENG,
        ProductCategory.MIE_INSTAN,
    ],
    ProductCategory.SEREAL: [
        ProductCategory.BISKUIT,
        ProductCategory.KERIPIK_SNACK,
    ],
    ProductCategory.MAKANAN_KALENG: [
        ProductCategory.FROZEN_FOOD,
        ProductCategory.MIE_INSTAN,
    ],
    ProductCategory.LAINNYA: [],
}
