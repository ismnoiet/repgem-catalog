import com.repgem.dustdissolve.*

// Many views at once: one scope, one controller per view.
@Composable
fun Tiles() {
    val dusts = remember { List(9) { DustDissolveController(DustDissolveConfiguration.Snap.copy(seed = it.toLong())) } }

    DustDissolveScope(dusts) {
        LazyVerticalGrid(GridCells.Fixed(3)) {
            itemsIndexed(dusts) { i, dust ->
                Tile(i, Modifier.dustSource(dust).clickable { dust.fire() })   // each tile has its own controller
            }
        }
    }
}
