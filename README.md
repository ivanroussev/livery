# livery

**Environment signals for Argo CD.** Know where you are before you press Sync.

Every Argo CD looks the same, so production and a dev sandbox are one
browser tab apart and look identical. livery keeps Argo CD's own look and
adds signals that are hard to miss:

- **Top bar and label:** a coloured bar across the top of every page, with
  the environment name hanging from it. Prod gets a hatched bar.
- **Window frame:** a thin line in the same colour around the whole window.
- **Sync warning:** the Synchronize button takes the environment colour and
  the Sync panel says *Syncing to PRODUCTION*.
- **Delete warning:** the OK button in Delete dialogs takes the environment
  colour. In prod, every Delete button is outlined in red as well.

Plain CSS: no build step on your side, no Argo CD fork.

## Supported apps

| App | Folder |
|---|---|
| Argo CD | [`argocd/`](argocd/) |

## Argo CD

### Files

| File | Colour | Label |
|---|---|---|
| `argocd/livery-prod.css` | Red, hatched bar | `PRODUCTION` |
| `argocd/livery-staging.css` | Amber | `STAGING` |
| `argocd/livery-dev.css` | Green | `DEVELOPMENT` |
| `argocd/livery-sandbox.css` | Blue | `SANDBOX` |

Argo CD loads one custom stylesheet, so each file is self-contained. Use
the one that matches the environment that Argo CD instance deploys to.

### Install

Argo CD loads a custom stylesheet from `ui.cssurl` in the `argocd-cm`
ConfigMap ([Argo CD docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/custom-styles/)).
Changes apply on the next page load; no restart needed.

#### Hosted

Point `ui.cssurl` at a pinned release:

```yaml
# argocd-cm
data:
  ui.cssurl: "https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.0/argocd/livery-prod.css"
```

With the [argo-cd Helm chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd):

```yaml
configs:
  cm:
    ui.cssurl: "https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.0/argocd/livery-prod.css"
```

Users' browsers fetch the file, so they need to reach the CDN. If your
Argo CD sends a strict `Content-Security-Policy`, allow the host in
`style-src`.

#### Self-hosted with Helm

The chart's `configs.styles` value stores the CSS in a ConfigMap, mounts
it into argocd-server and sets `ui.cssurl` for you:

```bash
helm upgrade argocd argo/argo-cd -n argocd --reuse-values \
  --set-file configs.styles=argocd/livery-prod.css
```

Don't also set `configs.cm."ui.cssurl"` with this method.

#### Self-hosted without Helm

argocd-server serves files mounted at `/shared/app/custom/` under
`/custom/`. Put the CSS in a ConfigMap:

```bash
kubectl -n argocd create configmap livery --from-file=argocd/livery-prod.css
```

Mount it into the `argocd-server` Deployment:

```yaml
spec:
  template:
    spec:
      containers:
        - name: argocd-server
          volumeMounts:
            - name: livery
              mountPath: /shared/app/custom
      volumes:
        - name: livery
          configMap:
            name: livery
```

Then set `ui.cssurl`:

```yaml
# argocd-cm
data:
  ui.cssurl: "./custom/livery-prod.css"
```

### Custom labels

If you run more than one cluster per environment, name the cluster in the
label, e.g. `PROD · EU-WEST-1`. The bar label and the Sync warning both use
it. Load livery first, then override the setting:

```css
@import url("https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.0/argocd/livery-prod.css");

:root {
  --livery-env-label: "PROD · EU-WEST-1";
}
```

With Helm, put that inline in `configs.styles`:

```yaml
configs:
  styles: |
    @import url("https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.0/argocd/livery-prod.css");
    :root { --livery-env-label: "PROD · EU-WEST-1"; }
```

When self-hosting, save the same two rules as a file next to
`livery-prod.css`, import it with `@import url("./livery-prod.css");`, and
point `ui.cssurl` at your file. The label is shown exactly as written.

Other settings you can change the same way:

| Setting | Default | What it does |
|---|---|---|
| `--livery-env-label` | `"PRODUCTION"` etc. | Label text, also used in the Sync warning |
| `--livery-env` | per file | Environment colour. Also set it under `:root:has(.theme-dark)` for dark mode |
| `--livery-env-ink` | per file | Text colour on top of `--livery-env` |
| `--livery-env-bar-height` | `5px` prod, `4px` others | Height of the top bar |
| `--livery-env-frame` | `3px` | Width of the window frame; `0px` turns it off |
| `--livery-env-frame-radius` | `14px` | Corner radius of the frame, to match rounded windows |

### Compatibility

Tested on Argo CD **v3.6.1** (light and dark mode) and **v2.13.0** (light mode).

The bar, label and frame don't depend on Argo CD's class names, so they
work on any version with `ui.cssurl`. The Sync and Delete signals do; if
a future version renames those classes, that signal stops showing and
nothing else breaks. They also need CSS `:has()`: Chrome or Edge 105+,
Safari 15.4+, Firefox 121+.

Argo CD adds the stylesheet after its settings load, so the signals
appear a moment after the first paint.

### Building

The files in `argocd/` are built from `argocd/src/`:

```bash
./argocd/build.sh
```

`src/settings.css` holds every setting and its default, `src/argocd.css`
maps them onto Argo CD's UI (`src/argocd-prod.css` adds the prod-only
Delete buttons), and `src/env/` sets the colours and label per environment.

## License

[Apache-2.0](LICENSE)
