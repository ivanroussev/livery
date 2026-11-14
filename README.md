# livery

**Environment signals for Argo CD, Apache Superset, Gitea and Forgejo.** Know where you
are before you press Sync.

Every Argo CD looks the same, so production and a dev sandbox are one
browser tab apart and look identical. livery keeps the app's own look and
adds signals that are hard to miss. In Argo CD:

- **Top bar and label:** a coloured bar across the top of every page, with
  the environment name hanging from it. Prod gets a hatched bar.
- **Window frame:** a thin line in the same colour around the whole window.
- **Sync warning:** the Synchronize button takes the environment colour and
  the Sync panel says *Syncing to PRODUCTION*.
- **Delete warning:** the OK button in Delete dialogs takes the environment
  colour. In prod, every Delete button is outlined in red as well.

[Superset](#apache-superset) gets the same bar, label and frame, with the
warnings on SQL Lab's Run button and on Delete.
[Gitea and Forgejo](#gitea-and-forgejo) get them with the warnings on the
Danger Zone and its dialogs.

Plain CSS: no build step on your side, no fork of the app.

## Supported apps

| App | Folder |
|---|---|
| Argo CD | [`argocd/`](argocd/) |
| Apache Superset | [`superset/`](superset/) |
| Gitea, Forgejo | [`gitea/`](gitea/) |

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
  ui.cssurl: "https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.1/argocd/livery-prod.css"
```

With the [argo-cd Helm chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd):

```yaml
configs:
  cm:
    ui.cssurl: "https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.1/argocd/livery-prod.css"
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
@import url("https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.1/argocd/livery-prod.css");

:root {
  --livery-env-label: "PROD · EU-WEST-1";
}
```

With Helm, put that inline in `configs.styles`:

```yaml
configs:
  styles: |
    @import url("https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.1.1/argocd/livery-prod.css");
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

## Apache Superset

- **Top bar, label and window frame:** the same as in Argo CD.
- **Run warning:** SQL Lab's Run button takes the environment colour, with
  *Runs on PRODUCTION* next to it.
- **Delete warning:** the Delete button in confirmation dialogs takes the
  environment colour. In prod, the Delete action in every list is outlined
  in red as well.

### Files

| File | Colour | Label |
|---|---|---|
| `superset/livery-prod.css` | Red, hatched bar | `PRODUCTION` |
| `superset/livery-staging.css` | Amber | `STAGING` |
| `superset/livery-dev.css` | Green | `DEVELOPMENT` |
| `superset/livery-sandbox.css` | Blue | `SANDBOX` |

### Install

Superset has no setting for a custom stylesheet. It does include a
template, `head_custom_extra.html`, in the `<head>` of every page, and
ships it empty with a note that it "may be overridden in your custom
deployment". livery uses that: you replace the template with one line
that loads the stylesheet. Restart Superset afterwards.

#### Self-hosted

Save this as `head_custom_extra.html`:

```html
<link rel="stylesheet" href="{{ assets_prefix }}/static/assets/livery-prod.css?v=0.2.0">
```

Mount it over the empty template, and the stylesheet into Superset's
static folder. With the official image:

```bash
docker run -d -p 8088:8088 \
  -v ./head_custom_extra.html:/app/superset/templates/head_custom_extra.html:ro \
  -v ./superset/livery-prod.css:/app/superset/static/assets/livery-prod.css:ro \
  apache/superset:6.1.0
```

On Kubernetes, put both files in a ConfigMap and mount each with
`subPath` at the same two paths, in every Superset web pod.

Superset tells browsers to cache static files for a year. Change the
`?v=` value whenever you change the file.

#### Hosted

Point the template at a pinned release:

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.2.0/superset/livery-prod.css">
```

Superset's default `Content-Security-Policy` only allows its own
stylesheets, so allow the CDN in `superset_config.py`:

```python
from superset.config import TALISMAN_CONFIG

TALISMAN_CONFIG["content_security_policy"]["style-src"].append("https://cdn.jsdelivr.net")
```

### Custom labels

Add a `<style>` after the link in `head_custom_extra.html`:

```html
<link rel="stylesheet" href="{{ assets_prefix }}/static/assets/livery-prod.css?v=0.2.0">
<style>
  :root { --livery-env-label: "PROD · EU-WEST-1"; }
</style>
```

The settings are the same as [Argo CD's](#custom-labels), with one
difference: for both themes, set a colour as
`light-dark(<light>, <dark>)` instead of adding a dark-mode rule.

### Compatibility

Tested on Superset **6.1.0**, in its light and dark themes.

The bar, label and frame don't depend on Superset's class names. The Run
and Delete signals use Superset's `data-test` attributes and Ant Design
class names; if a future version renames them, that signal stops showing
and nothing else breaks. They need CSS `:has()`. The dark-theme colours
need `light-dark()` (Chrome or Edge 123+, Safari 17.5+, Firefox 120+);
older browsers show the light-theme colours in both themes.

Embedded dashboards load the same template, so they get the bar and frame
too.

### Building

```bash
./superset/build.sh
```

The layout of `superset/src/` matches `argocd/src/`.

## Gitea and Forgejo

One set of files covers both.

- **Top bar, label and window frame:** the same as in Argo CD.
- **Danger Zone:** its header names the environment and its buttons are
  outlined in the environment colour. In prod, the header carries the
  hatched bar.
- **Delete, Transfer and Archive dialogs:** the title names the
  environment and the confirm button takes its colour, as do the other red
  buttons.

### Files

| File | Colour | Label |
|---|---|---|
| `gitea/livery-prod.css` | Red, hatched bar | `PRODUCTION` |
| `gitea/livery-staging.css` | Amber | `STAGING` |
| `gitea/livery-dev.css` | Green | `DEVELOPMENT` |
| `gitea/livery-sandbox.css` | Blue | `SANDBOX` |

### Install

Both apps load `templates/custom/header.tmpl` from the custom directory
into the `<head>` of every page, and serve files under `public/assets/`
([Gitea docs](https://docs.gitea.com/administration/customizing-gitea),
[Forgejo docs](https://forgejo.org/docs/latest/contributor/customization/)).
The custom directory is `/data/gitea` in both official Docker images.

Copy the stylesheet to `public/assets/css/` in the custom directory, and
save this as `templates/custom/header.tmpl`:

```html
<link rel="stylesheet" href="{{AssetUrlPrefix}}/css/livery-prod.css">
```

With Docker:

```bash
docker run -d -p 3000:3000 \
  -v ./header.tmpl:/data/gitea/templates/custom/header.tmpl:ro \
  -v ./gitea/livery-prod.css:/data/gitea/public/assets/css/livery-prod.css:ro \
  docker.gitea.com/gitea:latest
```

Restart after adding or changing the template. Browsers cache the
stylesheet for six hours.

To load a pinned release instead, point the link at
`https://cdn.jsdelivr.net/gh/ivanroussev/livery@v0.2.0/gitea/livery-prod.css`.

### Custom labels

Add a `<style>` after the link in `header.tmpl`:

```html
<link rel="stylesheet" href="{{AssetUrlPrefix}}/css/livery-prod.css">
<style>
  :root { --livery-env-label: "PROD · EU-WEST-1"; }
</style>
```

The settings are the same as [Argo CD's](#custom-labels). As with
Superset, set a colour for both themes as `light-dark(<light>, <dark>)`.

### Compatibility

Tested on Gitea **28.3.0** and Forgejo **15.0.11**, in their light, dark
and auto themes.

The bar, label and frame don't depend on either app's class names. The
Danger Zone and dialog signals do, and need CSS `:has()`; if a future
version renames those classes, that signal stops showing and nothing else
breaks. The dark-theme colours need `light-dark()` (Chrome or Edge 123+,
Safari 17.5+, Firefox 120+).

Forgejo's own accent colour is a burnt orange, close to the prod red. The
label and hatching still tell them apart.

### Building

```bash
./gitea/build.sh
```

## License

[Apache-2.0](LICENSE)
