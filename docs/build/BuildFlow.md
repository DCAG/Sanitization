# Build Flow

![BuildFlowStaticImage](BuildDependenciesGraph.jpg)

```mermaid
graph TD;
    D[UpdateMarkdownHelp]-->C
    E[CreateMarkdownHelp]-->C
    A[Publish]-->B[CreateExternalHelp]
    B-->C[Test]
    C-->F[Build]
    F-->G[PSScriptAnalyzer]
    F-->H[Clean]
    G-->I[Init]
```