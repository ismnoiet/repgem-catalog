import com.repgem.dragablecards.*

class Task(val id: Int, val title: String)

@Composable
fun Board() {
    val state = rememberDragBoardState(
        initialColumns = listOf(
            listOf(Task(1, "Design"), Task(2, "Build")),   // To do
            listOf(Task(3, "Ship")),                        // Doing
            emptyList(),                                    // Done
        ),
        itemKey = { it.id },
    )

    DragBoard(
        state = state,
        modifier = Modifier.fillMaxSize(),
        header = { index, tasks -> Text("${listOf("To do", "Doing", "Done")[index]} (${tasks.size})") },
        onMove = { task, from, to, index -> /* persist the move */ },
    ) { task ->
        Text(task.title, Modifier.fillMaxWidth().background(Color.White).padding(12.dp))
    }
}
